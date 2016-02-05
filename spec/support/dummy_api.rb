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
    end

    def get_user
    end

    def get_api_key(user, password)
      # get the api key, raise exception if credentials broken
      # this is a hash of the username and password plus salt
      return "some-api-key"
    end
  end
end
