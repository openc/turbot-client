# manage bots (generate skeleton, validate data, submit code)
#
class Turbot::Command::Bots < Turbot::Command::Base
  def initialize(*args)
    super

    require 'turbot_runner'
    require 'turbot/handlers/base_handler'
    require 'turbot/handlers/dump_handler'
    require 'turbot/handlers/preview_handler'
    require 'turbot/handlers/validation_handler'
  end

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
    response = api.show_bot(bot)
    if response.is_a? Turbot::API::FailureResponse
      error(response.message)
    end

    bot_data = response.data
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
      f.write(JSON.pretty_generate(JSON.load(manifest)))
    end

    response = api.create_bot(bot, JSON.load(manifest))
    if response.is_a? Turbot::API::SuccessResponse
      puts "Created new bot template at #{bot}!"
    else
      error(response.message)
    end
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

    manifest = parsed_manifest(working_directory)
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
    manifest = parsed_manifest(working_directory)
    archive = Tempfile.new(bot)
    archive_path = "#{archive.path}.zip"
    create_zip_archive(archive_path, working_directory, manifest['files'] + ['manifest.json'])

    response = File.open(archive_path) {|file| api.update_code(bot, file)}
    case response
    when Turbot::API::SuccessResponse
      puts "Your bot has been pushed to Turbot and will be reviewed for inclusion as soon as we can. THANK YOU!"
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
    scraper_path    = shift_argument || scraper_file(working_directory)
    validate_arguments!
    config = parsed_manifest(working_directory)

    %w(bot_id data_type identifying_fields files language publisher).each do |key|
      error("Manifest is missing #{key}") unless config.has_key?(key)
    end

    type = config["data_type"]

    handler = Turbot::Handlers::ValidationHandler.new
    runner = TurbotRunner::Runner.new(working_directory, :record_handler => handler)
    rc = runner.run

    puts
    if rc == TurbotRunner::Runner::RC_OK
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

    handler = Turbot::Handlers::DumpHandler.new
    runner = TurbotRunner::Runner.new(working_directory, :record_handler => handler)
    rc = runner.run

    puts
    if rc == TurbotRunner::Runner::RC_OK
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
#    scraper_path    = shift_argument || scraper_file(working_directory)
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

    config = parsed_manifest(working_directory)

    response = api.update_bot(bot, parsed_manifest(working_directory))
    if !response.is_a? Turbot::API::SuccessResponse
      error(response.message)
    end

    response = api.destroy_draft_data(bot)
    if !response.is_a? Turbot::API::SuccessResponse
      error(response.message)
    end

    puts "Sending to turbot... "

    handler = Turbot::Handlers::PreviewHandler.new(bot, api)
    runner = TurbotRunner::Runner.new(working_directory, :record_handler => handler)
    rc = runner.run

    puts

    if rc == TurbotRunner::Runner::RC_OK
      response = handler.submit_batch
      if response.is_a? Turbot::API::SuccessResponse
        if handler.count > 0
          puts "Submitted #{handler.count} records to turbot"
          puts "View your records at #{response.data[:url]}"
        else
          puts "No records sent"
        end
      else
        error(response.message)
      end
    else
      puts
      puts "Bot failed!"
    end
  end

  private

  def parsed_manifest(dir)
    begin
      JSON.load(open(manifest_path).read)
    rescue Errno::ENOENT
      raise "This command must be run from a directory including `manifest.json`"
    end
  end

  def scraper_file(dir)
    Dir.glob("scraper*").reject{|n| !n.match(/(rb|py)$/)}.first
  end

  def working_directory
    Dir.pwd
  end

  def manifest_path
    File.join(working_directory, 'manifest.json')
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
