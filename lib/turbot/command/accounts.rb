if Turbot::Plugin.list.include?('turbot-accounts')

  require "turbot/command/base"

  # manage multiple turbot accounts
  #
  class Turbot::Command::Accounts < Turbot::Command::Base

    # accounts:default
    # set a system-wide default account
    def default
      name = shift_argument
      validate_arguments!

      unless name
        error("Please specify an account name.")
      end

      unless account_exists?(name)
        error("That account does not exist.")
      end

      result = %x{ git config --global turbot.account #{name} }

      # update netrc
      Turbot::Auth.instance_variable_set(:@account, nil) # kill memoization
      Turbot::Auth.credentials = [Turbot::Auth.user, Turbot::Auth.password]
      Turbot::Auth.write_credentials

      result
    end

  end
end
