require 'rexml/document'
require 'uri'
require 'time'
require 'turbot/auth'
require 'turbot/command'
require 'turbot/helpers'
require 'turbot/version'

# A Ruby class to call the Turbot REST API.  You might use this if you want to
# manage your Turbot bots from within a Ruby program, such as Capistrano.
#
# Example:
#
#   require 'turbot'
#   turbot = Turbot::Client.new('me@example.com', 'mypass')
#   turbot.create()
#
class Turbot::Client

  include Turbot::Helpers
  extend Turbot::Helpers

  attr_accessor :host, :user, :password

  def initialize(user, password, host=Turbot::Auth.host)
    require 'rest_client'
    @user = user
    @password = password
    @host = host
  end

  def on_warning(&blk)
    @warning_callback = blk
  end

  ##################

  def resource(uri, options={})
    RestClient.proxy = case URI.parse(realize_full_uri(uri)).scheme
    when "http"
      http_proxy
    when "https"
      https_proxy
    end
    RestClient::Resource.new(realize_full_uri(uri), options.merge(:user => user, :password => password))
  end

  def get(uri, extra_headers={})    # :nodoc:
    process(:get, uri, extra_headers)
  end

  def post(uri, payload="", extra_headers={})    # :nodoc:
    process(:post, uri, extra_headers, payload)
  end

  def put(uri, payload, extra_headers={})    # :nodoc:
    process(:put, uri, extra_headers, payload)
  end

  def delete(uri, extra_headers={})    # :nodoc:
    process(:delete, uri, extra_headers)
  end

  def process(method, uri, extra_headers={}, payload=nil)
    headers  = turbot_headers.merge(extra_headers)
    args     = [method, payload, headers].compact

    resource_options = default_resource_options_for_uri(uri)

    begin
      response = resource(uri, resource_options).send(*args)
    rescue Errno::ECONNREFUSED, Errno::ETIMEDOUT, SocketError
      host = URI.parse(realize_full_uri(uri)).host
      error "Unable to connect to #{host}"
    rescue RestClient::SSLCertificateNotVerified => ex
      host = URI.parse(realize_full_uri(uri)).host
      error "WARNING: Unable to verify SSL certificate for #{host}\nTo disable SSL verification, run with TURBOT_SSL_VERIFY=disable"
    end

    extract_warning(response)
    response
  end

  def extract_warning(response)
    return unless response
    if response.headers[:x_turbot_warning] && @warning_callback
      warning = response.headers[:x_turbot_warning]
      @displayed_warnings ||= {}
      unless @displayed_warnings[warning]
        @warning_callback.call(warning)
        @displayed_warnings[warning] = true
      end
    end
  end

  def turbot_headers   # :nodoc:
    {
      'X-Turbot-API-Version' => '2',
      'User-Agent'           => Turbot.user_agent,
      'X-Ruby-Version'       => RUBY_VERSION,
      'X-Ruby-Platform'      => RUBY_PLATFORM
    }
  end

  def xml(raw)   # :nodoc:
    REXML::Document.new(raw)
  end

  def escape(value)  # :nodoc:
    escaped = URI.escape(value.to_s, Regexp.new("[^#{URI::PATTERN::UNRESERVED}]"))
    escaped.gsub('.', '%2E') # not covered by the previous URI.escape
  end

  module JSON
    def self.parse(json)
      json_decode(json)
    end
  end

  private

  def realize_full_uri(given)
    full_host = (host =~ /^http/) ? host : "https://api.#{host}"
    host = URI.parse(full_host)
    uri = URI.parse(given)
    uri.host ||= host.host
    uri.scheme ||= host.scheme || "https"
    uri.path = (uri.path[0..0] == "/") ? uri.path : "/#{uri.path}"
    uri.port = host.port if full_host =~ /\:\d+/
    uri.to_s
  end

  def default_resource_options_for_uri(uri)
    if ENV["TURBOT_SSL_VERIFY"] == "disable"
      {}
    elsif realize_full_uri(uri) =~ %r|^https://api.turbot.com|
      { :verify_ssl => OpenSSL::SSL::VERIFY_PEER, :ssl_ca_file => local_ca_file }
    else
      {}
    end
  end

  def local_ca_file
    File.expand_path("../../../data/cacert.pem", __FILE__)
  end

  def hash_from_xml_doc(elements)
    elements.inject({}) do |hash, e|
      next(hash) unless e.respond_to?(:children)
      hash.update(e.name.gsub("-","_").to_sym => case e.children.length
        when 0 then nil
        when 1 then e.text
        else hash_from_xml_doc(e.children)
      end)
    end
  end

  def http_proxy
    proxy = ENV['HTTP_PROXY'] || ENV['http_proxy']
    if proxy && !proxy.empty?
      unless /^[^:]+:\/\// =~ proxy
        proxy = "http://" + proxy
      end
      proxy
    else
      nil
    end
  end

  def https_proxy
    proxy = ENV['HTTPS_PROXY'] || ENV['https_proxy']
    if proxy && !proxy.empty?
      unless /^[^:]+:\/\// =~ proxy
        proxy = "https://" + proxy
      end
      proxy
    else
      nil
    end
  end
end
