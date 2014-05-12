require "turbot/command/base"
require "turbot/version"

# display version
#
class Turbot::Command::Version < Turbot::Command::Base

  # version
  #
  # show turbot client version
  #
  #Example:
  #
  # $ turbot version
  # turbot-toolbelt/1.2.3 (x86_64-darwin11.2.0) ruby/1.9.3
  #
  def index
    validate_arguments!

    display(Turbot.user_agent)
  end

end
