module Turbot
  class API
    def initialize(params)
      @headers = params[:headers]
      @host = params[:host]
      @port = params[:port]
      @username = params[:username]
      @password = params[:password]
      @scheme = params[:scheme]
      @ssl_verify_peer = params[:ssl_verify_peer]
      @api_key = params[:api_key] || get_api_key(@username, @password)
      authenticate
    end

    def authenticate
      # Try to authenticate at this stage - something like
      #user_pass = ":#{@api_key}"
      #options[:headers] = HEADERS.merge({
      #  'Authorization' => "Basic #{Base64.encode64(user_pass).gsub("\n", '')}",
      # }).merge(options[:headers])

      # @connection = Excon.new("http://missions.opencorporates.com/login", options)

    end

    def get_user
      # raise if not authenticated
      # @connection.code < 400
    end

    def get_api_key(user, password)
      # get the api key, raise exception if credentials broken
      # this is a hash of the username and password plus salt
      return "some-api-key"
    end

    def get_keys
      # return an array of ssh keys
    end

    def post_key(key)
      # receive ssh key and associate with account
    end

    def delete_keys
      # Do it!
    end

    def post_app(app)
      # save an "app" - we'll replace this with the bot stuff chris did
    end

    def delete_app(app)
      # dlete an "app" - we'll replace this with the bot stuff chris did
      # actually, not sure you're allowed to do this
    end
  end
end
