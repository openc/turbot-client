require "turbot/client"

class Turbot::Client::TurbotPostgresql
  Version = 11

  include Turbot::Helpers

  @headers = { :x_turbot_gem_version  => Turbot::Client.version }

  def self.add_headers(headers)
    @headers.merge! headers
  end

  def self.headers
    @headers
  end

  attr_reader :attachment
  def initialize(attachment)
    @attachment = attachment
    require 'rest_client'
  end

  def turbot_postgresql_host
    if attachment.starter_plan?
      determine_host(ENV["HEROKU_POSTGRESQL_HOST"], "postgres-starter-api.turbot.com")
    else
      if ENV['SHOGUN']
        "shogun-#{ENV['SHOGUN']}.turbotapp.com"
      else
        determine_host(ENV["HEROKU_POSTGRESQL_HOST"], "postgres-api.turbot.com")
      end
    end
  end

  def resource_name
    attachment.resource_name
  end

  def turbot_postgresql_resource
    RestClient::Resource.new(
      "https://#{turbot_postgresql_host}/client/v11/databases",
      :user => Turbot::Auth.user,
      :password => Turbot::Auth.password,
      :headers => self.class.headers
      )
  end

  def ingress
    http_put "#{resource_name}/ingress"
  end

  def reset
    http_put "#{resource_name}/reset"
  end

  def rotate_credentials
    http_post "#{resource_name}/credentials_rotation"
  end

  def get_database(extended=false)
    query = extended ? '?extended=true' : ''
    http_get resource_name + query
  end

  def get_wait_status
    http_get "#{resource_name}/wait_status"
  end

  def unfollow
    http_put "#{resource_name}/unfollow"
  end

  protected

  def sym_keys(c)
    if c.is_a?(Array)
      c.map { |e| sym_keys(e) }
    else
      c.inject({}) do |h, (k, v)|
        h[k.to_sym] = v; h
      end
    end
  end

  def checking_client_version
    begin
      yield
    rescue RestClient::BadRequest => e
      if message = json_decode(e.response.to_s)["upgrade_message"]
        abort(message)
      else
        raise e
      end
    end
  end

  def display_turbot_warning(response)
    warning = response.headers[:x_turbot_warning]
    display warning if warning
    response
  end

  def http_get(path)
    checking_client_version do
      retry_on_exception(RestClient::Exception) do
        response = turbot_postgresql_resource[path].get
        display_turbot_warning response
        sym_keys(json_decode(response.to_s))
      end
    end
  end

  def http_post(path, payload = {})
    checking_client_version do
      response = turbot_postgresql_resource[path].post(json_encode(payload))
      display_turbot_warning response
      sym_keys(json_decode(response.to_s))
    end
  end

  def http_put(path, payload = {})
    checking_client_version do
      response = turbot_postgresql_resource[path].put(json_encode(payload))
      display_turbot_warning response
      sym_keys(json_decode(response.to_s))
    end
  end

  private

  def determine_host(value, default)
    if value.nil?
      default
    else
      "#{value}.turbotapp.com"
    end
  end
end

module TurbotPostgresql
  class Client < Turbot::Client::TurbotPostgresql
    def initialize(*args)
      Turbot::Helpers.deprecate "TurbotPostgresql::Client has been deprecated. Please use Turbot::Client::TurbotPostgresql instead."
      super
    end
  end
end
