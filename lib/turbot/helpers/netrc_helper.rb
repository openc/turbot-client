module Turbot
  module Helpers
    extend self

    # Reads the user's email address and API key from either the `TURBOT_API_KEY`
    # environment variable or from a `.netrc` file.
    #
    # @return [Array<String>] the user's email address and API key
    def email_address_and_api_key
      if ENV['TURBOT_API_KEY']
        ['', ENV['TURBOT_API_KEY']]
      elsif netrc_exists?
        open_netrc["api.#{host}"] || []
      else
        []
      end
    end

    # Returns the path to the `.netrc` file containing the Turbot host's entry
    # with the user's email address and API key.
    #
    # @return [String] the path to the `.netrc` file
    def netrc_path
      unencrypted = Netrc.default_path
      encrypted = unencrypted + '.gpg'
      if File.exists?(encrypted)
        encrypted
      else
        unencrypted
      end
    end

    # Returns whether a `.netrc` file exists.
    #
    # @return [Boolean] whether a `.netrc` file exists
    def netrc_exists?
      File.exist?(netrc_path)
    end

    # Reads a `.netrc` file.
    #
    # @return [Netrc] the `.netrc` file
    def open_netrc
      begin
        Netrc.read(netrc_path)
      rescue Netrc::Error => e
        error e.message
      end
    end

    # Deletes the Turbot host's entry from the `.netrc` file.
    def delete_netrc_entry
      netrc = open_netrc
      netrc.delete("api.#{host}")
      netrc.save
    end

    # Saves the user's email address and AP key to the Turbot host's entry in the
    # `.netrc` file.
    def save_netrc_entry(email_address, api_key)
      netrc = open_netrc
      netrc["api.#{host}"] = [email_address, api_key]
      netrc.save
    end
  end
end
