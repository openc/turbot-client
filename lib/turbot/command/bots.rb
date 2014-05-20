require "turbot/command/base"

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
  # === Collaborated Bots
  # theirapp   other@owner.name
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
        data["Last run ended"] = format_date(bot_data["last_run_ended"])
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
  # # specify a name
  # $ heroku bots:create example
  # Creating example... done

  def create
    name    = shift_argument || options[:bot] || ENV['TURBOT_BOT']
    validate_arguments!

    params = {
      "name" => name,
    }

    api.post_bot(params).body
  end

  alias_command "create", "bots:create"
end
