#Login or logout from Turbot
#
class Turbot::Command::Auth < Turbot::Command::Base
  # auth
  #
  #Login or logout. Display your Turbot API token or email address.
  def index
    validate_arguments!
    Turbot::Command::Help.new.send(:help_for_command, current_command)
  end

  # auth:login
  #
  #Login to Turbot and save your Turbot credentials.
  #
  #Example:
  #
  #  $ turbot auth:login
  #  Enter your Turbot email and password:
  #  Email: email@example.com
  #  Password (typing will be hidden):
  #  Logged in. Saved Turbot API key.
  #
  def login
    validate_arguments!
    email_address, api_key = ask_for_email_address_and_password
    if api_key.empty?
      error 'Authentication failed.'
    end
    save_netrc_entry(email_address, api_key)
    puts 'Authentication successful.'
  end
  alias_command 'login', 'auth:login'

  # auth:logout
  #
  #Delete your Turbot credentials.
  #
  #Example:
  #
  #  $ turbot auth:logout
  #  Deleted Turbot credentials.
  #
  def logout
    validate_arguments!
    delete_netrc_entry
    puts 'Deleted Turbot credentials.'
  end
  alias_command 'logout', 'auth:logout'

  # auth:token
  #
  #Display your Turbot API token.
  #
  #Example:
  #
  #  $ turbot auth:token
  #  93a5c45595ed37dc9d040116
  #
  def token
    validate_arguments!
    result = email_address_and_api_key[1]
    if result
      puts result
    else
      error 'not logged in'
    end
  end

  # auth:whoami
  #
  #Display your Turbot email address.
  #
  #Example:
  #
  #  $ turbot auth:whoami
  #  email@example.com
  #
  def whoami
    validate_arguments!
    result = email_address_and_api_key[0]
    if result
      puts result
    else
      error 'not logged in'
    end
  end

private

  ### Shell-related

  # Prompts the user for an email address and password, and returns the email
  # address and the user's API key.
  #
  # @return [Array<String>] the user's email address and API key
  def ask_for_email_address_and_password
    puts 'Enter your Turbot email and password.'

    print 'Email: '
    email_address = ask

    print 'Password (typing will be hidden): '
    password = running_on_windows? ? ask_for_password_on_windows : ask_for_password

    puts

    [email_address, get_api_key(email_address, password)]
  end

  def running_on_windows?
    RUBY_PLATFORM =~ /mswin32|mingw32/
  end

  ### API-related

  # Gets the user's API key.
  #
  # @return [String] the API key, or the empty string if authentication fails
  def get_api_key(email_address, password)
    api.get_api_key_for_credentials(email_address, password)['api_key']
  end
end
