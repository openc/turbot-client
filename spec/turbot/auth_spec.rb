require "spec_helper"
require "turbot/auth"
require "turbot/helpers"

module Turbot
  describe Auth do
    include Turbot::Helpers

    before do
      ENV['TURBOT_API_KEY'] = nil

      @cli = Turbot::Auth
      @cli.stub(:check)
      @cli.stub(:display)
      @cli.stub(:running_on_a_mac?).and_return(false)
      @cli.credentials = nil

      FakeFS.activate!

      FakeFS::File.stub(:stat).and_return(double('stat', :mode => "0600".to_i(8)))
      FakeFS::FileUtils.stub(:chmod)
      FakeFS::File.stub(:readlines) do |path|
        File.read(path).split("\n").map {|line| "#{line}\n"}
      end

      FileUtils.mkdir_p(@cli.netrc_path.split("/")[0..-2].join("/"))

      File.open(@cli.netrc_path, "w") do |file|
        file.puts("machine api.turbot.com\n  login user\n  password pass\n")
        file.puts("machine code.turbot.com\n  login user\n  password pass\n")
      end
    end

    after do
      FileUtils.rm_rf(@cli.netrc_path)
      FakeFS.deactivate!
    end


    context "API key is set via environment variable" do
      before do
        ENV['TURBOT_API_KEY'] = "secret"
      end

      it "gets credentials from environment variables in preference to credentials file" do
        @cli.read_credentials.should == ['', ENV['TURBOT_API_KEY']]
      end

      it "returns a blank username" do
        @cli.user.should be_empty
      end

      it "returns the api key as the password" do
        @cli.password.should == ENV['TURBOT_API_KEY']
      end

      it "does not overwrite credentials file with environment variable credentials" do
        @cli.should_not_receive(:write_credentials)
        @cli.read_credentials
      end

      context "reauthenticating" do
        before do
          @cli.stub(:ask_for_credentials).and_return(['new_user', 'new_password'])
          @cli.stub(:check)
          @cli.reauthorize
        end
        it "updates saved credentials" do
          Netrc.read(@cli.netrc_path)["api.#{@cli.host}"].should == ['new_user', 'new_password']
        end
        it "returns environment variable credentials" do
          @cli.read_credentials.should == ['', ENV['TURBOT_API_KEY']]
        end
      end

    end

    describe "#base_host" do
      it "returns the host without the first part" do
        @cli.base_host("http://foo.bar.com").should == "bar.com"
      end

      it "works with localhost" do
        @cli.base_host("http://localhost:3000").should == "localhost"
      end
    end

    it "asks for credentials when the file doesn't exist" do
      @cli.delete_credentials
      @cli.should_receive(:ask_for_credentials).and_return(["u", "p"])
      @cli.user.should == 'u'
      @cli.password.should == 'p'
    end

    it "writes credentials and uploads authkey when credentials are saved" do
      @cli.stub(:credentials)
      @cli.stub(:check)
      @cli.stub(:ask_for_credentials).and_return("username", "apikey")
      @cli.should_receive(:write_credentials)
      @cli.ask_for_and_save_credentials
    end

    it "save_credentials deletes the credentials when the upload authkey is unauthorized" do
      @cli.stub(:write_credentials)
      @cli.stub(:retry_login?).and_return(false)
      @cli.stub(:ask_for_credentials).and_return("username", "apikey")
      @cli.stub(:check) { raise RestClient::Unauthorized }
      @cli.should_receive(:delete_credentials)
      lambda { @cli.ask_for_and_save_credentials }.should raise_error(SystemExit)
    end

    it "asks for login again when not authorized, for three times" do
      @cli.stub(:read_credentials)
      @cli.stub(:write_credentials)
      @cli.stub(:delete_credentials)
      @cli.stub(:ask_for_credentials).and_return("username", "apikey")
      @cli.stub(:check) { raise RestClient::Unauthorized }
      @cli.should_receive(:ask_for_credentials).exactly(3).times
      lambda { @cli.ask_for_and_save_credentials }.should raise_error(SystemExit)
    end

    it "writes the login information to the credentials file for the 'turbot login' command" do
      @cli.stub(:ask_for_credentials).and_return(['one', 'two'])
      @cli.stub(:check)
      @cli.reauthorize
      Netrc.read(@cli.netrc_path)["api.#{@cli.host}"].should == (['one', 'two'])
    end

    it "migrates long api keys to short api keys" do
      @cli.delete_credentials
      api_key = "7e262de8cac430d8a250793ce8d5b334ae56b4ff15767385121145198a2b4d2e195905ef8bf7cfc5"
      @cli.netrc["api.#{@cli.host}"] = ["user", api_key]

      @cli.get_credentials.should == ["user", api_key[0,40]]
      %w{api code}.each do |section|
        Netrc.read(@cli.netrc_path)["#{section}.#{@cli.host}"].should == ["user", api_key[0,40]]
      end
    end
  end
end
