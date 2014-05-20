require 'json'

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
      read_db("keys")
    end

    def post_key(key)
      # receive ssh key and associate with account
      append_db("keys", {"contents" => key})
    end

    def delete_key(key)
      keys = read_db("keys")
      keys.delete(key)
      write_db("keys", keys)
    end

    def delete_keys
      write_db("keys", [])
    end

    def post_bot(data)
      # XXX need to implement this to make the config command pass...
      # save an "bot" - we'll replace this with the bot stuff chris did
      db = read_db("bot")
      db[data["name"]] = data
      write_db("bot", db)
    end

    def delete_bot(bot)
      db = read_db("bot")
      db.delete(bot)
      write_db("bot", db)
    end

    def get_bots
      read_db("bot", [])
    end

    def get_bot(bot)
      db = read_db("bot_data", [])
      db[bot]
    end

    def put_config_vars(bot, vars)
      # Set vars for bot specified
      config = read_db("config")
      config[bot] = vars
      write_db("config", config)
    end

    def get_config_vars(bot)
      read_db("config", [])[bot]
    end

    def delete_config_var(bot, key)
      db = read_db("config", [])
      keys = db[bot]
      keys.delete(key)
      db[bot] = keys
      write_db("config", db)
    end

    private

    def write_db(name, data)
      open("/tmp/#{name}", "w") do |f|
        f.write(JSON.dump(data))
      end
    end

    def read_db(name, default={})
      JSON.parse(open("/tmp/#{name}", "r").read) rescue {}
    end

    def append_db(name, data)
      db = read_db(name, [])
      db << data
      write_db(name, db)
    end
  end
end
