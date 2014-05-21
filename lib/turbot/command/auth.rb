require "turbot/command/base"

# authentication (login, logout)
#
class Turbot::Command::Auth < Turbot::Command::Base

  # auth
  #
  # Authenticate, display token and current user
  def index
    validate_arguments!

    Turbot::Command::Help.new.send(:help_for_command, current_command)
  end

  # auth:login
  #
  # log in with your turbot credentials
  #
  #Example:
  #
  # $ turbot auth:login
  # Enter your Turbot credentials:
  # Email: email@example.com
  # Password (typing will be hidden):
  # Authentication successful.
  #
  def login
    validate_arguments!

    Turbot::Auth.login
    display "Authentication successful."
  end

  alias_command "login", "auth:login"

  # auth:logout
  #
  # clear local authentication credentials
  #
  #Example:
  #
  # $ turbot auth:logout
  # Local credentials cleared.
  #
  def logout
    validate_arguments!

    Turbot::Auth.logout
    display "Local credentials cleared."
  end

  alias_command "logout", "auth:logout"

  # auth:token
  #
  # display your api token
  #
  #Example:
  #
  # $ turbot auth:token
  # ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789ABCD
  #
  def token
    validate_arguments!

    display Turbot::Auth.api_key
  end

  # auth:whoami
  #
  # display your turbot email address
  #
  #Example:
  #
  # $ turbot auth:whoami
  # email@example.com
  #
  def whoami
    validate_arguments!

    display Turbot::Auth.user
  end

end
