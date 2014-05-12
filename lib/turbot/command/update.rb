require "turbot/command/base"
require "turbot/updater"

# update the turbot client
#
class Turbot::Command::Update < Turbot::Command::Base

  # update
  #
  # update the turbot client
  #
  # Example:
  #
  # $ turbot update
  # Updating from v1.2.3... done, updated to v2.3.4
  #
  def index
    validate_arguments!
    update_from_url("https://toolbelt.turbot.com/download/zip")
  end

  # update:beta
  #
  # update to the latest beta client
  #
  # $ turbot update
  # Updating from v1.2.3... done, updated to v2.3.4.pre
  #
  def beta
    validate_arguments!
    update_from_url("https://toolbelt.turbot.com/download/beta-zip")
  end

private

  def update_from_url(url)
    Turbot::Updater.check_disabled!
    action("Updating from #{Turbot::VERSION}") do
      if new_version = Turbot::Updater.update(url)
        status("updated to #{new_version}")
      else
        status("nothing to update")
      end
    end
  end

end
