require "cgi"
require "turbot"
require "turbot/client"
require "turbot/helpers"

require "netrc"

class Turbot::Auth
  class << self
    include Turbot::Helpers

    attr_accessor :credentials

    def api
      @api ||= begin
        Turbot::API.new(default_params.merge(:api_key => password))
      end
    end

    def client
      @client ||= begin
        client = Turbot::Client.new(user, password, host)
        client.on_warning { |msg| self.display("\n#{msg}\n\n") }
        client
      end
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

    def git_host
      ENV['TURBOT_GIT_HOST'] || host
    end

    def host
      ENV['TURBOT_HOST'] || default_host
    end

    def reauthorize
      self.credentials = ask_for_and_save_credentials
    end

    def user(ask_for_credentials = true)    # :nodoc:
      get_credentials(ask_for_credentials)[0]
    end

    def password(ask_for_credentials = true)    # :nodoc:
      get_credentials(ask_for_credentials)[1]
    end

    def api_key(ask_for_credentials = true)
      api.get_api_key(ask_for_credentials)
    end

    def api_key_for_credentials(user = get_credentials[0], password = get_credentials[1])
      user, password = get_credentials(ask_for_credentials)
      unless user.empty? && password.empty?
        api = Turbot::API.new(default_params)
        api.get_api_key_for_credentials(user, password)["api_key"]
      end
    end

    def get_credentials(ask_for_credentials = true)    # :nodoc:
      self.credentials ||= begin
        value = read_credentials
        if value
          value
        elsif ask_for_credentials
          ask_for_and_save_credentials
        else
          ['', '']
        end
      end
    end

    def delete_credentials
      if netrc
        netrc.delete("api.#{host}")
        netrc.delete("code.#{host}")
        netrc.save
      end
      @api = nil
      @client = nil
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

    def netrc   # :nodoc:
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
          self.credentials = [ value[0], value[1][0,40] ]
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

    def echo_off
      with_tty do
        system "stty -echo"
      end
    end

    def echo_on
      with_tty do
        system "stty echo"
      end
    end

    def ask_for_credentials
      puts "Enter your Turbot credentials."

      print "Email: "
      user = ask

      print "Password (typing will be hidden): "
      password = running_on_windows? ? ask_for_password_on_windows : ask_for_password

      [user, api_key_for_credentials(user, password)]
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
      echo_off
      password = ask
      puts
      echo_on
      return password
    end

    def ask_for_and_save_credentials
      begin
        # ask for username and password, look up API key against API given these
        # In looking up the API key it also attempts to log the user in
        self.credentials = ask_for_credentials
        # write these to a hidden file
        write_credentials
        check
      rescue RestClient::Unauthorized, Turbot::API::Errors::NotFound, Turbot::API::Errors::Unauthorized => e
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

    def retry_login?
      @login_attempts ||= 0
      @login_attempts += 1
      @login_attempts < 3
    end

    def verified_hosts
      %w( turbot.com turbot-shadow.com )
    end

    def base_host(host)
      parts = URI.parse(full_host(host)).host.split(".")
      return parts.first if parts.size == 1
      parts[-2..-1].join(".")
    end

    def full_host(host)
      (host =~ /^http/) ? host : "https://api.#{host}"
    end

    def verify_host?(host)
      hostname = base_host(host)
      verified = verified_hosts.include?(hostname)
      verified = false if ENV["TURBOT_SSL_VERIFY"] == "disable"
      verified
    end

    protected

    def default_params
      uri = URI.parse(full_host(host))
      {
        :headers          => {
          'User-Agent'    => Turbot.user_agent
        },
        :host             => uri.host,
        :port             => uri.port,
        :scheme           => uri.scheme,
        :ssl_verify_peer  => verify_host?(host)
      }
    end
  end
end
