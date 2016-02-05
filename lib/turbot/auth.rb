class Turbot::Auth
  class << self
    include Turbot::Helpers

    attr_accessor :credentials

    def api
      @api ||= turbot_api.new(default_params.merge(:api_key => password))
    end

    def login
      delete_credentials
      get_credentials
    end

    def logout
      delete_credentials
    end

    # will raise if not authenticated
    def check
      api.get_user
    end

    def default_host
      "http://turbot.opencorporates.com"
    end

    def host
      ENV['TURBOT_HOST'] || default_host
    end

    # Returns the users's name.
    #
    # @param [Boolean] force_login whether to login if not logged in
    # @return [String] the user's name
    def user(force_login = true)
      get_credentials(force_login)[0]
    end

    # Returns the user's password.
    #
    # @param [Boolean] force_login whether to login if not logged in
    # @return [String] the user's password
    def password(force_login = true)
      get_credentials(force_login)[1]
    end

    # Returns the user's API key.
    #
    # @return [String] the user's API key
    def api_key
      api.get_api_key
    end

    def delete_credentials
      if netrc
        netrc.delete("api.#{host}")
        netrc.delete("code.#{host}")
        netrc.save
      end
      @api = nil
      self.credentials = nil
    end

    def netrc_path
      default = Netrc.default_path
      encrypted = default + ".gpg"
      if File.exists?(encrypted)
        encrypted
      else
        default
      end
    end

    def netrc
      @netrc ||= begin
        File.exists?(netrc_path) && Netrc.read(netrc_path)
      rescue => error
        if error.message =~ /^Permission bits for/
          perm = File.stat(netrc_path).mode & 0777
          abort("Permissions #{perm} for '#{netrc_path}' are too open. You should run `chmod 0600 #{netrc_path}` so that your credentials are NOT accessible by others.")
        else
          raise error
        end
      end
    end

    def read_credentials
      if ENV['TURBOT_API_KEY']
        ['', ENV['TURBOT_API_KEY']]
      elsif netrc
        # read netrc credentials if they exist
        # force migration of long api tokens (80 chars) to short ones (40)
        # #write_credentials rewrites both api.* and code.*
        value = netrc["api.#{host}"]
        if value && value[1].length > 40
          self.credentials = [value[0], value[1][0, 40]]
          write_credentials
        end
        netrc["api.#{host}"]
      end
    end

    def write_credentials
      FileUtils.mkdir_p(File.dirname(netrc_path))
      FileUtils.touch(netrc_path)
      unless running_on_windows?
        FileUtils.chmod(0600, netrc_path)
      end
      netrc["api.#{host}"] = credentials
      netrc["code.#{host}"] = credentials
      netrc.save
    end

    # Gets the user's name and password.
    #
    # Tries to read the user's credentials from `.netrc`, then asks for
    # and saves the user's credentials if that's an option.
    #
    # @param [Boolean] force_login whether to login if not logged in
    # @return [Array<String>] the user's name and password, or an empty array
    def get_credentials(force_login = true)
      self.credentials ||= begin
        value = read_credentials
        if value
          value
        elsif force_login
          ask_for_and_save_credentials
        else
          []
        end
      end
    end

    def ask_for_and_save_credentials
      begin
        # ask for username and password, look up API key against API given these
        # In looking up the API key it also attempts to log the user in
        self.credentials = ask_for_credentials
        # write these to a hidden file
        write_credentials
        check
      rescue RestClient::Unauthorized => e
        delete_credentials
        display "Authentication failed."
        retry if retry_login?
        exit 1
      rescue Exception => e
        delete_credentials
        raise e
      end
      credentials
    end

    def ask_for_credentials
      puts "Enter your Turbot credentials."

      print "Email: "
      user = ask

      print "Password (typing will be hidden): "
      password = running_on_windows? ? ask_for_password_on_windows : ask_for_password

      api = turbot_api.new(default_params)
      [user, api.get_api_key_for_credentials(user, password)['api_key']]
    end

    def ask_for_password_on_windows
      require "Win32API"
      char = nil
      password = ''

      while char = Win32API.new("crtdll", "_getch", [ ], "L").Call do
        break if char == 10 || char == 13 # received carriage return or newline
        if char == 127 || char == 8 # backspace and delete
          password.slice!(-1, 1)
        else
          # windows might throw a -1 at us so make sure to handle RangeError
          (password << char.chr) rescue RangeError
        end
      end
      puts
      return password
    end

    def ask_for_password
      with_tty do
        system 'stty -echo'
      end

      password = ask

      puts

      with_tty do
        system 'stty echo'
      end

      password
    end

    def retry_login?
      @login_attempts ||= 0
      @login_attempts += 1
      @login_attempts < 3
    end

    # Used in tests only.
    def reauthorize # :nodoc:
      self.credentials = ask_for_and_save_credentials
    end

    private

    def turbot_api
      @turbot_api ||= begin
        require 'turbot_api'
        Turbot::API
      end
    end

    def default_params
      uri = URI.parse(host =~ /^http/ ? host : "https://api.#{host}")
      {
        :headers => {
          'User-Agent' => Turbot.user_agent
        },
        :host => uri.host,
        :port => uri.port,
        :scheme => uri.scheme,
      }
    end
  end
end
