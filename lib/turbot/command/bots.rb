require "turbot/command/base"
require 'active_support/core_ext/object/blank'
require 'active_support/core_ext/hash/slice'
require 'zip'
require 'json-schema'
require 'open3'
require 'base64'
require 'shellwords'

# manage bots (create, destroy)
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
    puts "running generate"
    validate_arguments!
    language = options[:language] || "ruby"
    puts "Generating #{language} code..."
    manifest_template = File.expand_path("../../../../templates/manifest.json", __FILE__)
    scraper_template = File.expand_path("../../../../templates/#{language}", __FILE__)
    license_template = File.expand_path("../../../../templates/LICENSE.txt", __FILE__)
    manifest = open(manifest_template).read.sub("{{bot_id}}", bot)
    scraper_name = case language
      when "ruby"
        "scraper.rb"
      when "python"
        "scraper.py"
      end

    manifest = manifest.sub("{{scraper_name}}", scraper_name)

    # Language-specific stuff
    FileUtils.cp_r(scraper_template, bot)

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
  # Creating example... done

  def push
    validate_arguments!

    working_dir = Dir.pwd
    manifest = parsed_manifest(working_dir)
    #archive_file = File.join(working_dir, 'tmp', "#{manifest['bot_id']}.zip")
    archive = Tempfile.new(bot)
    archive_path = "#{archive.path}.zip"

    Zip.continue_on_exists_proc = true
    Zip::File.open(archive_path, Zip::File::CREATE) do |zipfile|
      zipfile.add("manifest.json", manifest_path)
      manifest['files'].each { |f| zipfile.add(f, File.join(working_dir,f)) }
    end

    File.open(archive_path) do |file|
      api.update_code(bot, file)
    end
  end

  alias_command "push", "bots:push"

  # bots:validate
  #
  # Validate bot output against its schema
  #
  # $ heroku bots:validate
  # Validating example... done

  def validate
    scraper_path    = shift_argument || scraper_file(Dir.pwd)
    validate_arguments!
    config = parsed_manifest(Dir.pwd)

    %w(bot_id data_type identifying_fields files).each do |key|
      error("Manifest is missing #{key}") unless config.has_key?(key)
    end

    type = config["data_type"]

    schema = get_schema(type)

    if !schema || !File.exists?(schema)
      error("No schema found for data_type: #{type}")
    end

    count = 0

    run_scraper_each_line("#{scraper_path} #{bot}") do |line|
      errors = JSON::Validator.fully_validate(
        schema,
        line,
        {:errors_as_objects => true})

      if !errors.empty?
        error("LINE WITH ERROR: #{line}\n\nERRORS: #{errors}")
      end

      if JSON.parse(line).slice(*config['identifying_fields']).blank?
        error("LINE WITH ERROR: #{line}\n\nERRORS: No value provided for identifying fields")
      end

      count += 1
    end
    puts "Validated #{count} records successfully!"
  end

  # bots:dump
  #
  # Execute bot locally (writes to STDOUT)
  #
  # $ heroku bots:dump
  # {'foo': 'bar'}
  # {'foo2': 'bar2'}

  def dump
    # This will need to be language-aware, eventually
    scraper_path    = shift_argument || scraper_file(Dir.pwd)
    validate_arguments!
    count = 0
    run_scraper_each_line("#{scraper_path} #{bot}") do |line|
      puts line
      count += 1
    end
  end

  # bots:single
  #
  # Execute bot in same way as OpenCorporates single-record update
  #
  # $ heroku bots:single
  # Enter argument (as JSON object):
  # {"id": "frob123"}
  # {"id": "frob123", "stuff": "updated-data-for-this-record"}

  def single
    # This will need to be language-aware, eventually
    scraper_path    = shift_argument || scraper_file(Dir.pwd)
    validate_arguments!
    print 'Arguments (as JSON object, e.g. {"id":"ABC123"}: '
    arg = ask
    count = 0
    run_scraper_each_line("#{scraper_path} #{bot} #{Shellwords.shellescape(arg)}") do |line|
      raise "Your scraper returned more than one value!" if count > 1
      puts line
      count += 1
    end
  end


  # bots:preview
  #
  # Send bot data to Angler for remote previewing / sharing
  #
  # Sending example to Angler... done
  def preview
    scraper_path    = shift_argument || scraper_file(Dir.pwd)
    validate_arguments!

    batch = []
    count = 0
    config = parsed_manifest(Dir.pwd)
    puts "Sending to angler... "

    api.destroy_draft_data(bot)

    result = ""
    run_scraper_each_line("#{scraper_path} #{bot}") do |line|
      batch << JSON.parse(line)
      spinner(count)
      if count % 20 == 0
        result = api.create_draft_data(bot, config, batch.to_json)
        batch = []
      end
      count += 1
    end
    if !batch.empty?
      result = api.create_draft_data(bot, config, batch.to_json)
    end
    puts "Sent #{count} records."
    index_name = "#{bot}-#{config['data_type']}"
    puts "View your records at 'http://turbot.opencorporates.com/bots/#{index_name}'"
  end

  private

  def spinner(p)
    parts = "\|/-" * 2
    print parts[p % parts.length] + "\r"
  end

  def run_scraper_each_line(scraper_path, options={})
    case scraper_path
    when /scraper.rb /
      interpreter = "ruby"
    when /scraper.py /
      interpreter = "python"
    else
      raise "Unsupported file extension at #{scraper_path}"
    end

    command = "#{interpreter} #{scraper_path}"
    Open3::popen3(command, options) do |_, stdout, stderr, wait_thread|
      loop do
        check_output_with_timeout(stdout)

        begin
          result = stdout.readline.strip
          yield result unless result.empty?
          # add run id and bot name
        rescue EOFError
          break
        end
      end
      status = wait_thread.value.exitstatus
      if status > 0
        message = "Bot <#{command}> exited with status #{status}: #{stderr.read}"
        raise RuntimeError.new(message)
      end
    end
  end

  def check_output_with_timeout(stdout, initial_interval = 10, timeout = 21600)
    interval = initial_interval
    loop do
      reads, _, _ = IO.select([stdout], [], [], interval)
      break if !reads.nil?
      raise "Timeout! - could not read from external bot after #{timeout} seconds" if reads.nil? && interval > timeout
      interval *= 2
    end
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
end
