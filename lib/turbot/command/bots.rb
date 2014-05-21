require "turbot/command/base"
require 'zip'

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


  # bots:create [NAME]
  #
  # create a new bot
  #
  # # Must be run with a path to a manifest.json file
  # $ heroku bots:create path/to/manifest.json
  # Creating example... done

  def create
    manifest_path    = shift_argument
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
end
