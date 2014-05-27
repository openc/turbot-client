require "turbot/command/base"
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
    bots = api.get_bots
    unless bots.empty?
      styled_header("Bots")
      styled_array(bots.map{|k,data| data['name']})
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


  # bots:create [path/to/manifest.json]
  #
  # create a new bot
  #
  # # Must be run with a path to a manifest.json file
  # $ heroku bots:create path/to/manifest.json
  # Creating example... done

  def create
    manifest_path    = shift_argument || File.join(Dir.pwd, "manifest.json")
    validate_arguments!

    working_dir = File.dirname(manifest_path)
    manifest = JSON.parse(open(manifest_path).read)
    #archive_file = File.join(working_dir, 'tmp', "#{manifest['bot_id']}.zip")
    archive = Tempfile.new(manifest['bot_id'])
    archive_path = "#{archive.path}.zip"

    Zip.continue_on_exists_proc = true
    Zip::File.open(archive_path, Zip::File::CREATE) do |zipfile|
      zipfile.add("manifest.json", manifest_path)
      manifest['files'].each { |f| zipfile.add(f, File.join(working_dir,f)) }
    end

    File.open(archive_path) do |file|
      params = {
        "bot[archive]" => file,
        "bot[manifest]" => manifest
      }
      api.post_bot(params)
    end
  end

  alias_command "create", "bots:create"


  # bots:validate
  #
  # Validate bot output against its schema
  #
  # $ heroku bots:validate
  # Validating example... done

  def validate
    scraper_path    = shift_argument || File.join(Dir.pwd, "scraper.rb")
    validate_arguments!

    config = api.get_config_vars(bot)
    type = config["data_type"]

    if type == "primary_source"
      schema = nil
    else
      hyphenated_name = type.to_s.gsub("_", "-")
      schema = File.expand_path("../../../../schema/schemas/#{hyphenated_name}-schema.json", __FILE__)
    end
    any_errors = false
    count = 0
    run_scraper_each_line("#{scraper_path} #{bot}") do |line|
      errors = ""
      if schema
        errors = JSON::Validator.fully_validate(
          schema,
          line.to_json,
          {:errors_as_objects => true})
      else
        begin
          JSON.parse(line)
        rescue
          errors = "Not valid JSON"
        end
      end
      if !errors.empty?
        any_errors = true
        puts "LINE WITH ERROR:"
        puts line
        puts "ERRORS:"
        puts errors
        puts
      end
      count += 1
    end
    puts "Validated #{count} records successfully!" unless any_errors
  end

  # bots:dump [path/to/scraper.rb]
  #
  # Execute bot locally (writes to STDOUT)
  #
  # $ heroku bots:dump
  # {'foo': 'bar'}
  # {'foo2': 'bar2'}

  def dump
    # This will need to be language-aware, eventually
    scraper_path    = shift_argument || File.join(Dir.pwd, "scraper.rb")
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
    scraper_path    = shift_argument || File.join(Dir.pwd, "scraper.rb")
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
    scraper_path    = shift_argument || File.join(Dir.pwd, "scraper.rb")
    validate_arguments!
    batch = []
    count = 0
    puts "Sending to angler... "
    result = ""
    run_scraper_each_line("#{scraper_path} #{bot}") do |line|
      batch << JSON.parse(line)
      spinner(count)
      if count % 20 == 0
        result = api.send_drafts_to_angler(bot, batch.to_json)
        batch = []
      end
      count += 1
    end
    if !batch.empty?
      result = api.send_drafts_to_angler(bot, batch.to_json)
    end
    puts "Sent #{count} records."
    puts "View your records at #{JSON.parse(result)['url']}"
  end

  private

  def spinner(p)
    parts = "\|/-" * 2
    print parts[p % parts.length] + "\r"
  end

  def run_scraper_each_line(scraper_path, options={})
    command = "ruby #{scraper_path}"
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
end
