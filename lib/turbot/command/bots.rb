require "turbot/command/base"
require 'active_support/core_ext/object/blank'
require 'active_support/core_ext/hash/slice'
require 'zip'
require 'json-schema'
require 'open3'
require 'base64'
require 'shellwords'
require 'turbot_runner'

# manage bots (create, submit data and code)
#
class Turbot::Command::Bots < Turbot::Command::Base

  # bots
  #
  # list your bots
  #
  #Example:
  #
  # $ turbot bots
  # === My Bots
  # example
  # example2
  #
  def index
    validate_arguments!
    bots = api.list_bots.data
    unless bots.empty?
      styled_header("Bots")
      styled_array(bots.map{|bot| bot[:bot_id]})
    else
      display("You have no bots.")
    end
  end

  alias_command "list", "bots"

  # bots:info
  #
  # show detailed bot information
  #
  # -s, --shell  # output more shell friendly key/value pairs
  #
  #Examples:
  #
  # $ turbot bots:info
  # === example
  # Last run status: OK
  # Last run ended: 2001/01/01
  # ...
  #
  # $ turbot bots:info --shell
  # last_run_status: OK
  # last_run_ended: 2001/01/01
  # ...
  #
  def info
    validate_arguments!
    bot_data = api.get_bot(bot)
    unless options[:shell]
      styled_header(bot_data["name"])
    end

    if options[:shell]
      bot_data.keys.sort_by { |a| a.to_s }.each do |key|
        hputs("#{key}=#{bot_data[key]}")
      end
    else
      data = {}
      if bot_data["last_run_status"]
        data["Last run status"] = bot_data["last_run_status"]
      end
      if bot_data["last_run_ended"]
        data["Last run ended"] = format_date(bot_data["last_run_ended"]) if bot_data["last_run_ended"]
      end
      data["Git URL"] = bot_data["git_url"]
      data["Repo Size"] = format_bytes(bot_data["repo_size"]) if bot_data["repo_size"]
      styled_hash(data)
    end
  end

  alias_command "info", "bots:info"


  # bots:generate --bot name_of_bot
  #
  # Generate stub code for a bot in specified language
  #
  #   -l, --language LANGUAGE # language to generate (currently `ruby` (default) or `python`)

  # $ turbot bots:generate --language=ruby --bot my_amazing_bot
  # Created new bot template at my_amazing_bot!

  def generate
    validate_arguments!
    response = api.show_bot(bot)
    if response.is_a? Turbot::API::SuccessResponse
      error("There's already a bot called #{bot} registered with Turbot. Bot names must be unique.")
    end

    language = options[:language] || "ruby"
    scraper_template = File.expand_path("../../../../templates/#{language}", __FILE__)
    error("unsupported language #{language}") if !File.exists?(scraper_template)

    manifest_template = File.expand_path("../../../../templates/manifest.json", __FILE__)
    license_template = File.expand_path("../../../../templates/LICENSE.txt", __FILE__)
    manifest = open(manifest_template).read.sub("{{bot_id}}", bot)
    scraper_name = case language
      when "ruby"
        "scraper.rb"
      when "python"
        "scraper.py"
      end

    manifest = manifest.sub("{{scraper_name}}", scraper_name)
    manifest = manifest.sub("{{language}}", language)

    # Language-specific stuff
    # Language-specific stuff:
    if File.exists? bot
      error("There's already a folder called #{bot}; move it out the way or try a different name")
    end
    FileUtils.mkdir(bot)
    FileUtils.cp_r(Dir["#{scraper_template}/*"], bot)

    # Same for all languages
    FileUtils.cp(license_template, "#{bot}/LICENSE.txt")
    open("#{bot}/manifest.json", "w") do |f|
      f.write(JSON.pretty_generate(JSON.parse(manifest)))
    end
    api.create_bot(bot, JSON.parse(manifest))
    puts "Created new bot template at #{bot}!"
  end


  # bots:register
  #
  # Register a bot with turbot. Must be run from a folder containing scraper and manifest.json

  # $ turbot bots:register
  # Registered my_amazing_bot!

  def register
    response = api.show_bot(bot)
    if response.is_a? Turbot::API::SuccessResponse
      error("There's already a bot called #{bot} registered with Turbot. Bot names must be unique.")
    end

    working_dir = Dir.pwd
    manifest = parsed_manifest(working_dir)
    response = api.create_bot(bot, manifest)
    if response.is_a? Turbot::API::FailureResponse
      error(response.message)
    else
      puts "Registered #{bot}!"
    end
  end

  # bots:push
  #
  # Push bot code to the turbot server. Must be run from a local bot checkout.
  #
  # $ turbot bots:push
  # Your bot has been pushed to Turbot and will be reviewed for inclusion as soon as we can. THANKYOU!

  def push
    validate_arguments!
    puts "This will submit your bot and its data for review."
    puts "Are you happy your bot produces valid data (e.g. with `turbot bots:validate`)? [Y/n]"
    confirmed = ask
    error("Aborting push") if !confirmed.downcase.empty? && confirmed.downcase != "y"
    working_dir = Dir.pwd
    manifest = parsed_manifest(working_dir)
    archive = Tempfile.new(bot)
    archive_path = "#{archive.path}.zip"
    create_zip_archive(archive_path, working_dir, manifest['files'] + ['manifest.json'])

    response = File.open(archive_path) {|file| api.update_code(bot, file)}
    case response
    when Turbot::API::SuccessResponse
      puts "Your bot has been pushed to Turbot and will be reviewed for inclusion as soon as we can. THANKYOU!"
    when Turbot::API::FailureResponse
      error(response.message)
    end
  end

  alias_command "push", "bots:push"

  # bots:validate
  #
  # Validate bot output against its schema
  #
  # $ turbot bots:validate
  # Validating example... done

  def validate
    scraper_path    = shift_argument || scraper_file(Dir.pwd)
    validate_arguments!
    config = parsed_manifest(Dir.pwd)

    %w(bot_id data_type identifying_fields files publisher).each do |key|
      error("Manifest is missing #{key}") unless config.has_key?(key)
    end

    type = config["data_type"]

    schema = get_schema(type)

    if !schema || !File.exists?(schema)
      error("No schema found for data_type: #{type}")
    end

    handler = ValidationHandler.new
    runner = TurbotRunner::Runner.new(Dir.pwd, :record_handler => handler)
    rc = runner.run

    puts
    if rc
      puts "Validated #{handler.count} records!"
    else
      puts "Validated #{handler.count} records before bot failed!"
    end
  end

  # bots:dump
  #
  # Execute bot locally (writes to STDOUT)
  #
  # $ turbot bots:dump
  # {'foo': 'bar'}
  # {'foo2': 'bar2'}

  def dump
    validate_arguments!

    handler = DumpHandler.new
    runner = TurbotRunner::Runner.new(Dir.pwd, :record_handler => handler)
    rc = runner.run

    puts
    if rc
      puts "Bot ran successfully!"
    else
      puts "Bot failed!"
    end
  end

#  # bots:single
#  #
#  # Execute bot in same way as OpenCorporates single-record update
#  #
#  # $ turbot bots:single
#  # Enter argument (as JSON object):
#  # {"id": "frob123"}
#  # {"id": "frob123", "stuff": "updated-data-for-this-record"}
#
#  def single
#    # This will need to be language-aware, eventually
#    scraper_path    = shift_argument || scraper_file(Dir.pwd)
#    validate_arguments!
#    print 'Arguments (as JSON object, e.g. {"id":"ABC123"}: '
#    arg = ask
#    count = 0
#    run_scraper_each_line("#{scraper_path} #{bot} #{Shellwords.shellescape(arg)}") do |line|
#      raise "Your scraper returned more than one value!" if count > 1
#      puts line
#      count += 1
#    end
#  end


  # bots:preview
  #
  # Send bot data to Turbot for remote previewing / sharing
  #
  # Sending example to turbot... done
  def preview
    validate_arguments!

    config = parsed_manifest(Dir.pwd)
    api.update_bot(bot, parsed_manifest(Dir.pwd))
    api.destroy_draft_data(bot)
    puts "Sending to turbot... "

    handler = PreviewHandler.new(bot, api)
    runner = TurbotRunner::Runner.new(Dir.pwd, :record_handler => handler)
    rc = runner.run

    puts

    if rc
      response = handler.submit_batch
      if handler.count > 0
        puts "Submitted #{handler.count} records to turbot"
        puts "View your records at #{response.data[:url]}"
      else
        puts "No records sent"
      end
    else
      puts
      puts "Bot failed!"
    end
  end

  private
  def spinner(p)
    parts = "\|/-" * 2
    print parts[p % parts.length] + "\r"
  end

  def parsed_manifest(dir)
    begin
      JSON.parse(open(manifest_path).read)
    rescue Errno::ENOENT
      raise "This command must be run from a directory including `manifest.json`"
    end
  end

  def scraper_file(dir)
    Dir.glob("scraper*").reject{|n| !n.match(/(rb|py)$/)}.first
  end

  def manifest_path
    File.join(Dir.pwd, 'manifest.json')
  end

  def get_schema(type)
    hyphenated_name = type.to_s.gsub("_", "-").gsub(" ", "-")
    File.expand_path("../../../../schema/schemas/#{hyphenated_name}-schema.json", __FILE__)
  end

  def create_zip_archive(archive_path, basepath, subpaths)
    Zip.continue_on_exists_proc = true
    Zip::File.open(archive_path, Zip::File::CREATE) do |zipfile|
      subpaths.each do |subpath|
        path = File.join(basepath, subpath)

        if File.directory?(path)
          Dir["#{path}/**/*"].each do |path1|
            subpath1 = Pathname.new(path1).relative_path_from(Pathname.new(basepath))
            zipfile.add(subpath1, path1)
          end
        else
          zipfile.add(subpath, path)
        end
      end
    end
  end
end

class TurbotClientHandler < TurbotRunner::BaseHandler
  def handle_invalid_record(record, data_type, errors)
    puts
    puts "The following record is invalid:"
    puts record.to_json
    errors.each {|error| puts " * #{error}"}
    puts
  end

  def handle_non_json_output(line)
    puts
    puts "The following line was not valid JSON:"
    puts line
  end
end


class DumpHandler < TurbotClientHandler
  def handle_valid_record(record, data_type)
    puts record.to_json
  end
end


class ValidationHandler < TurbotClientHandler
  attr_reader :count

  def initialize(*)
    @count = 0
    super
  end

  def handle_valid_record(record, data_type)
    @count += 1
    STDOUT.write('.')
  end

  def handle_invalid_record(record, data_type, errors)
    puts
    puts "The following record is invalid:"
    puts record.to_json
    errors.each {|error| puts " * #{error}"}
    puts
  end

  def handle_invalid_json(line)
    puts
    puts "The following line was not valid JSON:"
    puts line
  end
end


class PreviewHandler < TurbotClientHandler
  attr_reader :count

  def initialize(bot_name, api)
    @bot_name = bot_name
    @api = api
    @batch = []
    @count = 0
    super()
  end

  def handle_valid_record(record, data_type)
    @count += 1
    STDOUT.write('.')
    @batch << record.merge(:data_type => data_type)
    submit_batch if @count % 20 == 0
  end

  def submit_batch
    result = @api.create_draft_data(@bot_name, @batch.to_json)
    @batch = []
    result
  end
end
