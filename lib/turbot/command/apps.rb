require "turbot/command/base"

# manage apps (create, destroy)
#
class Turbot::Command::Apps < Turbot::Command::Base

  # apps
  #
  # list your apps
  #
  #Example:
  #
  # $ turbot apps
  # === My Apps
  # example
  # example2
  #
  # === Collaborated Apps
  # theirapp   other@owner.name
  #
  def index
    validate_arguments!
    apps = api.get_apps
    unless apps.empty?
      styled_header("Apps")
      styled_array(apps.map{|k,data| data['name']})
    else
      display("You have no apps.")
    end
  end

  alias_command "list", "apps"

  # apps:info
  #
  # show detailed app information
  #
  # -s, --shell  # output more shell friendly key/value pairs
  #
  #Examples:
  #
  # $ turbot apps:info
  # === example
  # Git URL:   git@turbot.com:example.git
  # Repo Size: 5M
  # ...
  #
  # $ turbot apps:info --shell
  # git_url=git@turbot.com:example.git
  # repo_size=5000000
  # ...
  #
  def info
    validate_arguments!
    app_data = api.get_app(app)
    unless options[:shell]
      styled_header(app_data["name"])
    end

    if options[:shell]
      app_data.keys.sort_by { |a| a.to_s }.each do |key|
        hputs("#{key}=#{app_data[key]}")
      end
    else
      data = {}
      if app_data["last_run_status"]
        data["Last run status"] = app_data["last_run_status"]
      end
      if app_data["last_run_ended"]
        data["Last run ended"] = format_date(app_data["last_run_ended"])
      end
      data["Git URL"] = app_data["git_url"]
      data["Repo Size"] = format_bytes(app_data["repo_size"]) if app_data["repo_size"]
      styled_hash(data)
    end
  end

  alias_command "info", "apps:info"
end
