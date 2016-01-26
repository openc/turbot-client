require "spec_helper"
require "turbot/client"
require "turbot/helpers"
require 'turbot/command'

describe Turbot::Client do
  include Turbot::Helpers

  before do
    @client = Turbot::Client.new(nil, nil)
    @resource = double('turbot rest resource')
    @client.stub(:extract_warning)
  end

  it "Client.auth -> get user details" do
    user_info = { "api_key" => "abc" }
    stub_request(:post, "http://foo:bar@turbot.opencorporates.com/login").to_return(:body => json_encode(user_info))
    capture_stderr do # capture deprecation message
      Turbot::Client.auth("foo", "bar").should == user_info
    end
  end

  it "list -> get a list of this user's bots" do
    stub_api_request(:get, "/bots").to_return(:body => <<-EOXML)
      <?xml version='1.0' encoding='UTF-8'?>
      <bots type="array">
        <bot><name>example</name><owner>test@turbot.com</owner></bot>
        <bot><name>example2</name><owner>test@turbot.com</owner></bot>
      </bots>
    EOXML
    capture_stderr do # capture deprecation message
      @client.list.should == [
        ["example", "test@turbot.com"],
        ["example2", "test@turbot.com"]
      ]
    end
  end

  it "info -> get bot attributes" do
    stub_api_request(:get, "/bots/example").to_return(:body => <<-EOXML)
      <?xml version='1.0' encoding='UTF-8'?>
      <bot>
        <blessed type='boolean'>true</blessed>
        <created-at type='datetime'>2008-07-08T17:21:50-07:00</created-at>
        <id type='integer'>49134</id>
        <name>example</name>
        <production type='boolean'>true</production>
        <share-public type='boolean'>true</share-public>
        <domain_name/>
      </bot>
    EOXML
    @client.stub(:list_collaborators).and_return([:jon, :mike])
    @client.stub(:installed_addons).and_return([:addon1])
    capture_stderr do # capture deprecation message
      @client.info('example').should == { :blessed => 'true', :created_at => '2008-07-08T17:21:50-07:00', :id => '49134', :name => 'example', :production => 'true', :share_public => 'true', :domain_name => nil, :collaborators => [:jon, :mike], :addons => [:addon1] }
    end
  end

  it "create_request -> create a new blank bot" do
    stub_api_request(:post, "/bots").with(:body => "").to_return(:body => <<-EOXML)
      <?xml version="1.0" encoding="UTF-8"?>
      <bot><name>untitled-123</name></bot>
    EOXML
    capture_stderr do # capture deprecation message
      @client.create_request.should == "untitled-123"
    end
  end

  it "create_request(name) -> create a new blank bot with a specified name" do
    stub_api_request(:post, "/bots").with(:body => "bot[name]=newapp").to_return(:body => <<-EOXML)
      <?xml version="1.0" encoding="UTF-8"?>
      <bot><name>newapp</name></bot>
    EOXML
    capture_stderr do # capture deprecation message
      @client.create_request("newapp").should == "newapp"
    end
  end

  it "create_complete?(name) -> checks if a create request is complete" do
    @response = double('response')
    @response.should_receive(:code).and_return(202)
    @client.should_receive(:resource).and_return(@resource)
    @resource.should_receive(:put).with({}, @client.turbot_headers).and_return(@response)
    capture_stderr do # capture deprecation message
      @client.create_complete?('example').should eq(false)
    end
  end

  it "update(name, attributes) -> updates existing bots" do
    stub_api_request(:put, "/bots/example").with(:body => "bot[mode]=production")
    capture_stderr do # capture deprecation message
      @client.update("example", :mode => 'production')
    end
  end

  it "destroy(name) -> destroy the named bot" do
    stub_api_request(:delete, "/bots/destroyme")
    capture_stderr do # capture deprecation message
      @client.destroy("destroyme")
    end
  end

  it "rake(bot_name, cmd) -> run a rake command on the bot" do
    stub_api_request(:post, "/bots/example/services").with(:body => "rake db:migrate").to_return(:body => "foo")
    stub_api_request(:get,  "/foo").to_return(:body => "output")
    capture_stderr do # capture deprecation message
      @client.rake('example', 'db:migrate')
    end
  end

  it "console(bot_name, cmd) -> run a console command on the bot" do
    stub_api_request(:post, "/bots/example/console").with(:body => "command=2%2B2")
    @client.console('example', '2+2')
  end

  it "console(bot_name) { |c| } -> opens a console session, yields one accessor and closes it after the block" do
    stub_api_request(:post,   "/bots/example/consoles").to_return(:body => "consolename")
    stub_api_request(:post,   "/bots/example/consoles/consolename/command").with(:body => "command=1%2B1").to_return(:body => "2")
    stub_api_request(:delete, "/bots/example/consoles/consolename")

    @client.console('example') do |c|
      c.run("1+1").should == '=> 2'
    end
  end

  it "shows an error message when a console request fails" do
    stub_request(:post, %r{.*/bots/example/console}).to_return({
      :body => "ERRMSG", :status => 502
    })
    lambda { @client.console('example') }.should raise_error(Turbot::Client::AppCrashed, /Your application may have crashed/)
  end

  it "restart(bot_name) -> restarts the bot servers" do
    stub_api_request(:delete, "/bots/example/server")
    capture_stderr do # capture deprecation message
      @client.restart('example')
    end
  end

  describe "read_logs" do
    describe "old style" do
      before(:each) do
        stub_api_request(:get, "/bots/example/logs?logplex=true").to_return(:body => "Use old logs")
        stub_api_request(:get, "/bots/example/logs").to_return(:body => "oldlogs")
      end

      it "can read old style logs" do
        @client.should_receive(:puts).with("oldlogs")
        @client.read_logs("example")
      end
    end

    describe "new style" do
      before(:each) do
        stub_api_request(:get, "/bots/example/logs?logplex=true").to_return(:body => "https://logplex.turbot.com/identifier")
        stub_request(:get, "https://logplex.turbot.com/identifier").to_return(:body => "newlogs")
      end

      it "can read new style logs" do
        @client.read_logs("example") do |logs|
          logs.should == "newlogs"
        end
      end
    end
  end

  it "logs(bot_name) -> returns recent output of the bot logs" do
    stub_api_request(:get, "/bots/example/logs").to_return(:body => "log")
    capture_stderr do # capture deprecation message
      @client.logs('example').should == 'log'
    end
  end

  it "can get the number of dynos" do
    stub_api_request(:get, "/bots/example").to_return(:body => <<-EOXML)
      <?xml version='1.0' encoding='UTF-8'?>
      <bot>
        <dynos type='integer'>5</dynos>
      </bot>
    EOXML
    capture_stderr do # capture deprecation message
      @client.dynos('example').should == 5
    end
  end

  it "can get the number of workers" do
    stub_api_request(:get, "/bots/example").to_return(:body => <<-EOXML)
      <?xml version='1.0' encoding='UTF-8'?>
      <bot>
        <workers type='integer'>5</workers>
      </bot>
    EOXML
    capture_stderr do # capture deprecation message
      @client.workers('example').should == 5
    end
  end

  it "set_dynos(bot_name, qty) -> scales the bot" do
    stub_api_request(:put, "/bots/example/dynos").with(:body => "dynos=3")
    capture_stderr do # capture deprecation message
      @client.set_dynos('example', 3)
    end
  end

  it "rake catches 502s and shows the bot crashlog" do
    e = RestClient::RequestFailed.new
    e.stub(:http_code).and_return(502)
    e.stub(:http_body).and_return('the crashlog')
    @client.should_receive(:post).and_raise(e)
    capture_stderr do # capture deprecation message
      lambda { @client.rake('example', '') }.should raise_error(Turbot::Client::AppCrashed)
    end
  end

  it "rake passes other status codes (i.e., 500) as standard restclient exceptions" do
    e = RestClient::RequestFailed.new
    e.stub(:http_code).and_return(500)
    e.stub(:http_body).and_return('not a crashlog')
    @client.should_receive(:post).and_raise(e)
    capture_stderr do # capture deprecation message
      lambda { @client.rake('example', '') }.should raise_error(RestClient::RequestFailed)
    end
  end

  describe "ps_scale" do
    it "scales a process and returns the new count" do
      stub_api_request(:post, "/bots/example/ps/scale").with(:body => { :type => "web", :qty => "5" }).to_return(:body => "5")
      capture_stderr do # capture deprecation message
        @client.ps_scale("example", :type => "web", :qty => "5").should == 5
      end
    end
  end

  describe "collaborators" do
    it "list(bot_name) -> list bot collaborators" do
      stub_api_request(:get, "/bots/example/collaborators").to_return(:body => <<-EOXML)
        <?xml version="1.0" encoding="UTF-8"?>
        <collaborators type="array">
          <collaborator><email>joe@example.com</email></collaborator>
          <collaborator><email>jon@example.com</email></collaborator>
        </collaborators>
      EOXML
      capture_stderr do # capture deprecation message
        @client.list_collaborators('example').should == [
          { :email => 'joe@example.com' },
          { :email => 'jon@example.com' }
        ]
      end
    end

    it "add_collaborator(bot_name, email) -> adds collaborator to bot" do
      stub_api_request(:post, "/bots/example/collaborators").with(:body => "collaborator%5Bemail%5D=joe%40example.com")
      capture_stderr do # capture deprecation message
        @client.add_collaborator('example', 'joe@example.com')
      end
    end

    it "remove_collaborator(bot_name, email) -> removes collaborator from bot" do
      stub_api_request(:delete, "/bots/example/collaborators/joe%40example%2Ecom")
      capture_stderr do # capture deprecation message
        @client.remove_collaborator('example', 'joe@example.com')
      end
    end
  end

  describe "domain names" do
    it "list(bot_name) -> list bot domain names" do
      stub_api_request(:get, "/bots/example/domains").to_return(:body => <<-EOXML)
        <?xml version="1.0" encoding="UTF-8"?>
        <domains type="array">
          <domain-name><domain>example1.com</domain></domain-name>
          <domain-name><domain>example2.com</domain></domain-name>
        </domains>
      EOXML
      capture_stderr do # capture deprecation message
        @client.list_domains('example').should == [{:domain => 'example1.com'}, {:domain => 'example2.com'}]
      end
    end

    it "add_domain(bot_name, domain) -> adds domain name to bot" do
      stub_api_request(:post, "/bots/example/domains").with(:body => "example.com")
      capture_stderr do # capture deprecation message
        @client.add_domain('example', 'example.com')
      end
    end

    it "remove_domain(bot_name, domain) -> removes domain name from bot" do
      stub_api_request(:delete, "/bots/example/domains/example.com")
      capture_stderr do # capture deprecation message
        @client.remove_domain('example', 'example.com')
      end
    end

    it "remove_domain(bot_name, domain) -> makes sure a domain is set" do
      lambda do
        capture_stderr do # capture deprecation message
          @client.remove_domain('example', '')
        end
      end.should raise_error(ArgumentError)
    end

    it "remove_domains(bot_name) -> removes all domain names from bot" do
      stub_api_request(:delete, "/bots/example/domains")
      capture_stderr do # capture deprecation message
        @client.remove_domains('example')
      end
    end

    it "add_ssl(bot_name, pem, key) -> adds a ssl cert to the domain" do
      stub_api_request(:post, "/bots/example/ssl").with do |request|
        body = CGI::parse(request.body)
        body["key"].first.should == "thekey"
        body["pem"].first.should == "thepem"
      end.to_return(:body => "{}")
      @client.add_ssl('example', 'thepem', 'thekey')
    end

    it "remove_ssl(bot_name, domain) -> removes the ssl cert for the domain" do
      stub_api_request(:delete, "/bots/example/domains/example.com/ssl")
      @client.remove_ssl('example', 'example.com')
    end
  end

  describe "SSH keys" do
    it "fetches a list of the user's current keys" do
      stub_api_request(:get, "/user/keys").to_return(:body => <<-EOXML)
        <?xml version="1.0" encoding="UTF-8"?>
        <keys type="array">
          <key>
            <contents>ssh-dss thekey== joe@workstation</contents>
          </key>
        </keys>
      EOXML
      capture_stderr do # capture deprecation message
        @client.keys.should == [ "ssh-dss thekey== joe@workstation" ]
      end
    end

    it "add_key(key) -> add an SSH key (e.g., the contents of id_rsa.pub) to the user" do
      stub_api_request(:post, "/user/keys").with(:body => "a key")
      capture_stderr do # capture deprecation message
        @client.add_key('a key')
      end
    end

    it "remove_key(key) -> remove an SSH key by name (user@box)" do
      stub_api_request(:delete, "/user/keys/joe%40workstation")
      capture_stderr do # capture deprecation message
        @client.remove_key('joe@workstation')
      end
    end

    it "remove_all_keys -> removes all SSH keys for the user" do
      stub_api_request(:delete, "/user/keys")
      capture_stderr do # capture deprecation message
        @client.remove_all_keys
      end
    end

    it "maintenance(bot_name, :on) -> sets maintenance mode for an bot" do
      stub_api_request(:post, "/bots/example/server/maintenance").with(:body => "maintenance_mode=1")
      capture_stderr do # capture deprecation message
        @client.maintenance('example', :on)
      end
    end

    it "maintenance(bot_name, :off) -> turns off maintenance mode for an bot" do
      stub_api_request(:post, "/bots/example/server/maintenance").with(:body => "maintenance_mode=0")
      capture_stderr do # capture deprecation message
        @client.maintenance('example', :off)
      end
    end
  end

  describe "config vars" do
    it "config_vars(bot_name) -> json hash of config vars for the bot" do
      stub_api_request(:get, "/bots/example/config_vars").to_return(:body => '{"A":"one", "B":"two"}')
      capture_stderr do # capture deprecation message
        @client.config_vars('example').should == { 'A' => 'one', 'B' => 'two'}
      end
    end

    it "add_config_vars(bot_name, vars)" do
      stub_api_request(:put, "/bots/example/config_vars").with(:body => '{"x":"y"}')
      capture_stderr do # capture deprecation message
        @client.add_config_vars('example', {'x'=> 'y'})
      end
    end

    it "remove_config_var(bot_name, key)" do
      stub_api_request(:delete, "/bots/example/config_vars/mykey")
      capture_stderr do # capture deprecation message
        @client.remove_config_var('example', 'mykey')
      end
    end

    it "clear_config_vars(bot_name) -> resets all config vars for this bot" do
      stub_api_request(:delete, "/bots/example/config_vars")
      capture_stderr do # capture deprecation message
        @client.clear_config_vars('example')
      end
    end

    it "can handle config vars with special characters" do
      stub_api_request(:delete, "/bots/example/config_vars/foo%5Bbar%5D")
      capture_stderr do # capture deprecation message
        lambda { @client.remove_config_var('example', 'foo[bar]') }.should_not raise_error
      end
    end
  end

  describe "addons" do
    it "addons -> array with addons available for installation" do
      stub_api_request(:get, "/addons").to_return(:body => '[{"name":"addon1"}, {"name":"addon2"}]')
      @client.addons.should == [{'name' => 'addon1'}, {'name' => 'addon2'}]
    end

    it "installed_addons(bot_name) -> array of installed addons" do
      stub_api_request(:get, "/bots/example/addons").to_return(:body => '[{"name":"addon1"}]')
      @client.installed_addons('example').should == [{'name' => 'addon1'}]
    end

    it "install_addon(bot_name, addon_name)" do
      stub_api_request(:post, "/bots/example/addons/addon1")
      @client.install_addon('example', 'addon1').should be_nil
    end

    it "upgrade_addon(bot_name, addon_name)" do
      stub_api_request(:put, "/bots/example/addons/addon1")
      @client.upgrade_addon('example', 'addon1').should be_nil
    end

    it "downgrade_addon(bot_name, addon_name)" do
      stub_api_request(:put, "/bots/example/addons/addon1")
      @client.downgrade_addon('example', 'addon1').should be_nil
    end

    it "uninstall_addon(bot_name, addon_name)" do
      stub_api_request(:delete, "/bots/example/addons/addon1?").
        to_return(:body => json_encode({"message" => nil, "price" => "free", "status" => "uninstalled"}))

      @client.uninstall_addon('example', 'addon1').should be_truthy
    end

    it "uninstall_addon(bot_name, addon_name) with confirmation" do
      stub_api_request(:delete, "/bots/example/addons/addon1?confirm=example").
        to_return(:body => json_encode({"message" => nil, "price" => "free", "status" => "uninstalled"}))

      @client.uninstall_addon('example', 'addon1', :confirm => "example").should be_truthy
    end

    it "install_addon(bot_name, addon_name) with response" do
      stub_request(:post, "http://turbot.opencorporates.com/bots/example/addons/addon1").
        to_return(:body => json_encode({'price' => 'free', 'message' => "Don't Panic"}))

      @client.install_addon('example', 'addon1').
        should == { 'price' => 'free', 'message' => "Don't Panic" }
    end

    it "upgrade_addon(bot_name, addon_name) with response" do
      stub_request(:put, "http://turbot.opencorporates.com/bots/example/addons/addon1").
        to_return(:body => json_encode('price' => 'free', 'message' => "Don't Panic"))

      @client.upgrade_addon('example', 'addon1').
        should == { 'price' => 'free', 'message' => "Don't Panic" }
    end

    it "downgrade_addon(bot_name, addon_name) with response" do
      stub_request(:put, "http://turbot.opencorporates.com/bots/example/addons/addon1").
        to_return(:body => json_encode('price' => 'free', 'message' => "Don't Panic"))

      @client.downgrade_addon('example', 'addon1').
        should == { 'price' => 'free', 'message' => "Don't Panic" }
    end

    it "uninstall_addon(bot_name, addon_name) with response" do
      stub_api_request(:delete, "/bots/example/addons/addon1?").
        to_return(:body => json_encode('price'=> 'free', 'message'=> "Don't Panic"))

      @client.uninstall_addon('example', 'addon1').
        should == { 'price' => 'free', 'message' => "Don't Panic" }
    end
  end

  describe "internal" do
    before do
      @client = Turbot::Client.new(nil, nil)
    end

    it "creates a RestClient resource for making calls" do
      @client.stub(:host).and_return('turbot.com')
      @client.stub(:user).and_return('joe@example.com')
      @client.stub(:password).and_return('secret')

      res = @client.resource('/xyz')

      res.url.should == 'https://api.turbot.com/xyz'
      res.user.should == 'joe@example.com'
      res.password.should == 'secret'
    end

    it "appends the api. prefix to the host" do
      @client.host = "turbot.com"
      @client.resource('/xyz').url.should == 'https://api.turbot.com/xyz'
    end

    it "doesn't add the api. prefix to full hosts" do
      @client.host = 'http://resource'
      res = @client.resource('/xyz')
      res.url.should == 'http://resource/xyz'
    end

    it "runs a callback when the API sets a warning header" do
      response = double('rest client response', :headers => { :x_turbot_warning => 'Warning' })
      @client.should_receive(:resource).and_return(@resource)
      @resource.should_receive(:get).and_return(response)
      @client.on_warning { |msg| @callback = msg }
      @client.get('test')
      @callback.should == 'Warning'
    end

    it "doesn't run the callback twice for the same warning" do
      response = double('rest client response', :headers => { :x_turbot_warning => 'Warning' })
      @client.stub(:resource).and_return(@resource)
      @resource.stub(:get).and_return(response)
      @client.on_warning { |msg| @callback_called ||= 0; @callback_called += 1 }
      @client.get('test1')
      @client.get('test2')
      @callback_called.should == 1
    end
  end

  describe "stacks" do
    it "list_stacks(bot_name) -> json hash of available stacks" do
      stub_api_request(:get, "/bots/example/stack?include_deprecated=false").to_return(:body => '{"stack":"one"}')
      capture_stderr do # capture deprecation message
        @client.list_stacks("example").should == { 'stack' => 'one' }
      end
    end

    it "list_stacks(bot_name, include_deprecated=true) passes the deprecated option" do
      stub_api_request(:get, "/bots/example/stack?include_deprecated=true").to_return(:body => '{"stack":"one"}')
      capture_stderr do # capture deprecation message
        @client.list_stacks("example", :include_deprecated => true).should == { 'stack' => 'one' }
      end
    end
  end
end
