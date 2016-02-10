#Display version
#
class Turbot::Command::Version < Turbot::Command::Base

  # version
  #
  #Show the Turbot client's version.
  #
  #Example:
  #
  #  $ turbot version
  #  turbot-gem/0.1.36 (x86_64-darwin14) ruby/2.2.0
  #
  def index
    validate_arguments!
    puts "#{Turbot::DEBUG_VERSION}"
  end
  alias_command '--version', 'version'
end
