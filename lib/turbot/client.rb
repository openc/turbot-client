require 'rexml/document'
require 'uri'
require 'time'
require 'turbot/auth'
require 'turbot/command'
require 'turbot/helpers'
require 'turbot/version'
require 'turbot/client/ssl_endpoint'

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

  def self.version
    Turbot::VERSION
  end

  def self.gem_version_string
    "turbot-gem/#{version}"
  end

  attr_accessor :host, :user, :password

  def initialize(user, password, host=Turbot::Auth.host)
    require 'rest_client'
    @user = user
    @password = password
    @host = host
  end

  def self.deprecate
    method = caller.first.split('`').last[0...-1]
    source = caller[1].split(' ').first[0...-3]
    $stderr.puts(" !    DEPRECATED: Turbot::Client##{method} is deprecated, please use the turbot-api gem.")
    $stderr.puts(" !    DEPRECATED: More information available at https://github.com/openc/turbot-client")
    $stderr.puts(" !    DEPRECATED: Deprecated method called from #{source}.")
  end

  def deprecate
    self.class.deprecate
  end

  def self.auth(user, password, host=Turbot::Auth.host)
    deprecate # 08/01/2012
    client = new(user, password, host)
    json_decode client.post('/login', { :username => user, :password => password }, :accept => 'json').to_s
  end

  # Show a list of bots which you are a collaborator on.
  def list
    deprecate # 07/26/2012
    doc = xml(get('/bots').to_s)
    doc.elements.to_a("//bots/bot").map do |a|
      name = a.elements.to_a("name").first
      owner = a.elements.to_a("owner").first
      [name.text, owner.text]
    end
  end

  # Show info such as mode, custom domain, and collaborators on an bot.
  def info(name_or_domain)
    deprecate # 07/26/2012
    raise ArgumentError.new("name_or_domain is required for info") unless name_or_domain
    name_or_domain = name_or_domain.gsub(/^(http:\/\/)?(www\.)?/, '')
    doc = xml(get("/bots/#{name_or_domain}").to_s)
    attrs = hash_from_xml_doc(doc)[:bot]
    attrs.merge!(:collaborators => list_collaborators(attrs[:name]))
    attrs.merge!(:addons        => installed_addons(attrs[:name]))
  end

  # Create a new bot, with an optional name.
  def create(name=nil, options={})
    deprecate # 07/26/2012
    name = create_request(name, options)
    loop do
      break if create_complete?(name)
      sleep 1
    end
    name
  end

  def create_bot(name=nil, options={})
    deprecate # 07/26/2012
    options[:name] = name if name
    json_decode(post("/bots", { :bot => options }, :accept => "application/json").to_s)
  end

  def create_request(name=nil, options={})
    deprecate # 07/26/2012
    options[:name] = name if name
    xml(post('/bots', :bot => options).to_s).elements["//bot/name"].text
  end

  def create_complete?(name)
    deprecate # 07/26/2012
    put("/bots/#{name}/status", {}).code == 201
  end

  # Update an bot.  Available attributes:
  #   :name => rename the bot (changes http and git urls)
  def update(name, attributes)
    deprecate # 07/26/2012
    put("/bots/#{name}", :bot => attributes).to_s
  end

  # Destroy the bot permanently.
  def destroy(name)
    deprecate # 07/26/2012
    delete("/bots/#{name}").to_s
  end

  def maintenance(bot_name, mode)
    deprecate # 07/31/2012
    mode = mode == :on ? '1' : '0'
    post("/bots/#{bot_name}/server/maintenance", :maintenance_mode => mode).to_s
  end

  def config_vars(bot_name)
    deprecate # 07/27/2012
    json_decode get("/bots/#{bot_name}/config_vars", :accept => :json).to_s
  end

  def add_config_vars(bot_name, new_vars)
    deprecate # 07/27/2012
    put("/bots/#{bot_name}/config_vars", json_encode(new_vars), :accept => :json).to_s
  end

  def remove_config_var(bot_name, key)
    deprecate # 07/27/2012
    delete("/bots/#{bot_name}/config_vars/#{escape(key)}", :accept => :json).to_s
  end

  def clear_config_vars(bot_name)
    deprecate # 07/27/2012
    delete("/bots/#{bot_name}/config_vars").to_s
  end

  # Get a list of collaborators on the bot, returns an array of hashes each with :email
  def list_collaborators(bot_name)
    deprecate # 07/31/2012
    doc = xml(get("/bots/#{bot_name}/collaborators").to_s)
    doc.elements.to_a("//collaborators/collaborator").map do |a|
      { :email => a.elements['email'].text }
    end
  end

  # Invite a person by email address to collaborate on the bot.
  def add_collaborator(bot_name, email)
    deprecate # 07/31/2012
    xml(post("/bots/#{bot_name}/collaborators", { 'collaborator[email]' => email }).to_s)
  end

  # Remove a collaborator.
  def remove_collaborator(bot_name, email)
    deprecate # 07/31/2012
    delete("/bots/#{bot_name}/collaborators/#{escape(email)}").to_s
  end

  def list_domains(bot_name)
    deprecate # 08/02/2012
    doc = xml(get("/bots/#{bot_name}/domains").to_s)
    doc.elements.to_a("//domains/*").map do |d|
      attrs = { :domain => d.elements['domain'].text }
      if cert = d.elements['cert']
        attrs[:cert] = {
          :expires_at => Time.parse(cert.elements['expires-at'].text),
          :subject    => cert.elements['subject'].text,
          :issuer     => cert.elements['issuer'].text,
        }
      end
      attrs
    end
  end

  def add_domain(bot_name, domain)
    deprecate # 07/31/2012
    post("/bots/#{bot_name}/domains", domain).to_s
  end

  def remove_domain(bot_name, domain)
    deprecate # 07/31/2012
    raise ArgumentError.new("invalid domain: #{domain.inspect}") if domain.to_s.strip == ""
    delete("/bots/#{bot_name}/domains/#{domain}").to_s
  end

  def remove_domains(bot_name)
    deprecate # 07/31/2012
    delete("/bots/#{bot_name}/domains").to_s
  end

  # Get the list of ssh public keys for the current user.
  def keys
    deprecate # 07/31/2012
    doc = xml get('/user/keys').to_s
    doc.elements.to_a('//keys/key').map do |key|
      key.elements['contents'].text
    end
  end

  # Add an ssh public key to the current user.
  def add_key(key)
    deprecate # 07/31/2012
    post("/user/keys", key, { 'Content-Type' => 'text/ssh-authkey' }).to_s
  end

  # Remove an existing ssh public key from the current user.
  def remove_key(key)
    deprecate # 07/31/2012
    delete("/user/keys/#{escape(key)}").to_s
  end

  # Clear all keys on the current user.
  def remove_all_keys
    deprecate # 07/31/2012
    delete("/user/keys").to_s
  end

  # Retreive ps list for the given bot name.
  def ps(bot_name)
    deprecate # 07/31/2012
    json_decode get("/bots/#{bot_name}/ps", :accept => 'application/json').to_s
  end

  # Restart the bot servers.
  def restart(bot_name)
    deprecate # 07/31/2012
    delete("/bots/#{bot_name}/server").to_s
  end

  def dynos(bot_name)
    deprecate # 07/31/2012
    doc = xml(get("/bots/#{bot_name}").to_s)
    doc.elements["//bot/dynos"].text.to_i
  end

  def workers(bot_name)
    deprecate # 07/31/2012
    doc = xml(get("/bots/#{bot_name}").to_s)
    doc.elements["//bot/workers"].text.to_i
  end

  # Scales the web dynos.
  def set_dynos(bot_name, qty)
    deprecate # 07/31/2012
    put("/bots/#{bot_name}/dynos", :dynos => qty).to_s
  end

  # Scales the background dynos.
  def set_workers(bot_name, qty)
    deprecate # 07/31/2012
    put("/bots/#{bot_name}/workers", :workers => qty).to_s
  end

  def ps_run(bot, opts={})
    deprecate # 07/31/2012
    json_decode post("/bots/#{bot}/ps", opts, :accept => :json).to_s
  end

  def ps_scale(bot, opts={})
    deprecate # 07/31/2012
    Integer(post("/bots/#{bot}/ps/scale", opts).to_s)
  end

  def ps_restart(bot, opts={})
    deprecate # 07/31/2012
    post("/bots/#{bot}/ps/restart", opts)
  end

  def ps_stop(bot, opts={})
    deprecate # 07/31/2012
    post("/bots/#{bot}/ps/stop", opts)
  end

  def releases(bot)
    deprecate # 07/31/2012
    json_decode get("/bots/#{bot}/releases", :accept => :json).to_s
  end

  def release(bot, release)
    deprecate # 07/31/2012
    json_decode get("/bots/#{bot}/releases/#{release}", :accept => :json).to_s
  end

  def rollback(bot, release=nil)
    deprecate # 07/31/2012
    post("/bots/#{bot}/releases", :rollback => release)
  end

  # Fetch recent logs from the bot server.
  def logs(bot_name)
    deprecate # 07/31/2012
    get("/bots/#{bot_name}/logs").to_s
  end

  def list_features(bot)
    deprecate # 07/31/2012
    json_decode(get("features?bot=#{bot}", :accept => :json).to_s)
  end

  def get_feature(bot, name)
    deprecate # 07/31/2012
    json_decode get("features/#{name}?bot=#{bot}", :accept => :json).to_s
  end

  def enable_feature(bot, name)
    deprecate # 07/31/2012
    json_decode post("/features/#{name}?bot=#{bot}", :accept => :json).to_s
  end

  def disable_feature(bot, name)
    deprecate # 07/31/2012
    json_decode delete("/features/#{name}?bot=#{bot}", :accept => :json).to_s
  end

  # Get a list of stacks available to the bot, with the current one marked.
  def list_stacks(bot_name, options={})
    deprecate # 07/31/2012
    include_deprecated = options.delete(:include_deprecated) || false

    json_decode get("/bots/#{bot_name}/stack",
      :params => { :include_deprecated => include_deprecated },
      :accept => 'application/json'
    ).to_s
  end

  # Request a stack migration.
  def migrate_to_stack(bot_name, stack)
    deprecate # 07/31/2012
    put("/bots/#{bot_name}/stack", stack, :accept => 'text/plain').to_s
  end

  # Run a rake command on the Turbot bot and return output as a string
  def rake(bot_name, cmd)
    # deprecated by virtue of start deprecation 08/02/2012
    start(bot_name, "rake #{cmd}", :attached).to_s
  end

  class Service
    attr_accessor :attached

    def initialize(client, bot)
      require 'rest_client'
      @client = client
      @bot = bot
    end

    # start the service
    def start(command, attached=false)
      @attached = attached
      @response = @client.post(
        "/bots/#{@bot}/services",
        command,
        :content_type => 'text/plain'
      )
      @next_chunk = @response.to_s
      @interval = 0
      self
    rescue RestClient::RequestFailed => e
      raise AppCrashed, e.http_body  if e.http_code == 502
      raise
    end

    # Does the service have any remaining output?
    def end_of_stream?
      @next_chunk.nil?
    end

    # Read the next chunk of output.
    def read
      chunk = @client.get(@next_chunk)
      if chunk.headers[:location].nil? && chunk.code != 204
        # no more chunks
        @next_chunk = nil
        chunk.to_s
      elsif chunk.to_s == ''
        # assume no content and back off
        @interval = 2
        ''
      elsif location = chunk.headers[:location]
        # some data read and next chunk available
        @next_chunk = location
        @interval = 0
        chunk.to_s
      end
    end

    # Iterate over all output chunks until EOF is reached.
    def each
      until end_of_stream?
        sleep(@interval)
        output = read
        yield output unless output.empty?
      end
    end

    # All output as a string
    def to_s
      buf = []
      each { |part| buf << part }
      buf.join
    end
  end

  # Run a service. If Responds to #each and yields output as it's received.
  def start(bot_name, command, attached=false)
    deprecate # 08/02/2012
    service = Service.new(self, bot_name)
    service.start(command, attached)
  end

  def add_ssl(bot_name, pem, key)
    json_decode(post("/bots/#{bot_name}/ssl", :pem => pem, :key => key).to_s)
  end

  def remove_ssl(bot_name, domain)
    delete("/bots/#{bot_name}/domains/#{domain}/ssl").to_s
  end

  def clear_ssl(bot_name)
    delete("/bots/#{bot_name}/ssl")
  end

  class AppCrashed < RuntimeError; end

  # support for console sessions
  class ConsoleSession
    def initialize(id, bot, client)
      require 'rest_client'
      @id = id; @bot = bot; @client = client
    end
    def run(cmd)
      @client.run_console_command("/bots/#{@bot}/consoles/#{@id}/command", cmd, "=> ")
    end
  end

  # Execute a one-off console command, or start a new console tty session if
  # cmd is nil.
  def console(bot_name, cmd=nil)
    if block_given?
      id = post("/bots/#{bot_name}/consoles").to_s
      yield ConsoleSession.new(id, bot_name, self)
      delete("/bots/#{bot_name}/consoles/#{id}").to_s
    else
      run_console_command("/bots/#{bot_name}/console", cmd)
    end
  rescue RestClient::BadGateway => e
    raise(AppCrashed, <<-ERROR)
Unable to attach to a dyno to open a console session.
Your application may have crashed.
Check the output of "turbot ps" and "turbot logs" for more information.
    ERROR
  end

  # internal method to run console commands formatting the output
  def run_console_command(url, command, prefix=nil)
    output = post(url, { :command => command }, :accept => "text/plain").to_s
    return output unless prefix
    if output.include?("\n")
      lines  = output.split("\n")
      (lines[0..-2] << "#{prefix}#{lines.last}").join("\n")
    else
      prefix + output
    end
  rescue RestClient::RequestFailed => e
    if e.http_code == 422
      Turbot::Command.extract_error(e.http_body, :raw => true)
    else
      raise e
    end
  end

  def read_logs(bot_name, options=[])
    query = "&" + options.join("&") unless options.empty?
    url = get("/bots/#{bot_name}/logs?logplex=true#{query}").to_s
    if url == 'Use old logs'
      puts get("/bots/#{bot_name}/logs").to_s
    else
      uri  = URI.parse(url);

      if uri.scheme == 'https'
        proxy = https_proxy
      else
        proxy = http_proxy
      end

      if proxy
        proxy_uri = URI.parse(proxy)
        http = Net::HTTP.new(uri.host, uri.port, proxy_uri.host, proxy_uri.port, proxy_uri.user, proxy_uri.password)
      else
        http = Net::HTTP.new(uri.host, uri.port)
      end

      if uri.scheme == 'https'
        http.use_ssl = true
        if ENV["TURBOT_SSL_VERIFY"] == "disable"
          http.verify_mode = OpenSSL::SSL::VERIFY_NONE
        else
          http.verify_mode = OpenSSL::SSL::VERIFY_PEER
          http.ca_file = local_ca_file
          http.verify_callback = lambda do |preverify_ok, ssl_context|
            if (!preverify_ok) || ssl_context.error != 0
              error "WARNING: Unable to verify SSL certificate for #{host}\nTo disable SSL verification, run with TURBOT_SSL_VERIFY=disable"
            end
            true
          end
        end
      end

      http.read_timeout = 60 * 60 * 24

      begin
        http.start do
          http.request_get(uri.path + (uri.query ? "?" + uri.query : "")) do |response|
            error(response.message) if response.is_a? Net::HTTPServerError
            response["Tail-warning"] && $stderr.puts(response["X-Turbot-Warning"])
            response.read_body do |chunk|
              yield chunk
            end
          end
        end
      rescue Errno::ECONNREFUSED, Errno::ETIMEDOUT, SocketError
        error("Could not connect to logging service")
      rescue Timeout::Error, EOFError
        error("\nRequest timed out")
      end
    end
  end

  def list_drains(bot_name)
    get("/bots/#{bot_name}/logs/drains").to_s
  end

  def add_drain(bot_name, url)
    post("/bots/#{bot_name}/logs/drains", "url=#{CGI.escape(url)}").to_s
  end

  def remove_drain(bot_name, url)
    delete("/bots/#{bot_name}/logs/drains?url=#{CGI.escape(url)}").to_s
  end

  def addons(filters = {})
    url = "/addons"
    params = filters.map{|k,v| "#{k}=#{v}"}.join("&")
    params = nil if params.empty?
    json_decode get([url,params].compact.join("?"), :accept => 'application/json').to_s
  end

  def installed_addons(bot_name)
    json_decode get("/bots/#{bot_name}/addons", :accept => 'application/json').to_s
  end

  def install_addon(bot_name, addon, config={})
    configure_addon :install, bot_name, addon, config
  end

  def upgrade_addon(bot_name, addon, config={})
    configure_addon :upgrade, bot_name, addon, config
  end
  alias_method :downgrade_addon, :upgrade_addon

  def uninstall_addon(bot_name, addon, options={})
    configure_addon :uninstall, bot_name, addon, options
  end

  def httpcache_purge(bot_name)
    delete("/bots/#{bot_name}/httpcache").to_s
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

  def configure_addon(action, bot_name, addon, config = {})
    response = update_addon action,
                            addon_path(bot_name, addon),
                            config

    json_decode(response.to_s) unless response.to_s.empty?
  end

  def addon_path(bot_name, addon)
    "/bots/#{bot_name}/addons/#{escape(addon)}"
  end

  def update_addon(action, path, config)
    params  = { :config => config }
    bot     = params[:config].delete(:confirm)
    headers = { :accept => 'application/json' }
    params.merge!(:confirm => bot) if bot

    case action
    when :install
      post path, params, headers
    when :upgrade
      put path, params, headers
    when :uninstall
      confirm = bot ? "confirm=#{bot}" : ''
      delete "#{path}?#{confirm}", headers
    end
  end

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
