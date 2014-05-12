require "spec_helper"
require "turbot/command"
require 'json' #FOR WEBMOCK

class FakeResponse

  attr_accessor :body, :headers

  def initialize(attributes)
    self.body, self.headers = attributes[:body], attributes[:headers]
  end

  def to_s
    body
  end

end

describe Turbot::Command do
  before {
    Turbot::Command.load
    stub_core # setup fake auth
  }

  describe "when the command requires confirmation" do

    let(:response_that_requires_confirmation) do
      {:status => 423,
       :headers => { :x_confirmation_required => 'my_addon' },
       :body => 'terms of service required'}
    end

    context "when the app is unknown" do
      context "and the user includes --confirm APP" do
        it "should set --app to APP and not ask for confirmation" do
          stub_request(:post, %r{apps/XXX/addons/my_addon$}).
            with(:body => {:confirm => "XXX"})
          run "addons:add my_addon --confirm XXX"
        end
      end

      context "and the user includes --confirm APP --app APP2" do
        it "should warn that the app and confirm do not match and not continue" do
          capture_stderr do
            run "addons:add my_addon --confirm APP --app APP2"
          end.should == " !    Mismatch between --app and --confirm\n"
        end
      end
    end

    context "and the app is known" do
      before do
        any_instance_of(Turbot::Command::Base) do |base|
          stub(base).app.returns("example")
        end
      end

      context "and the user includes --confirm WRONGAPP" do
        it "should not allow include the option" do
          stub_request(:post, %r{apps/example/addons/my_addon$}).
            with(:body => "")
          run "addons:add my_addon --confirm XXX"
        end
      end

      context "and the user includes --confirm APP" do
        it "should set --app to APP and not ask for confirmation" do
          stub_request(:post, %r{apps/example/addons/my_addon$}).
            with(:body => {:confirm => 'example'})

          run "addons:add my_addon --confirm example"
        end
      end

      context "and the user didn't include a confirm flag" do
        it "should ask the user for confirmation" do
          stub(Turbot::Command).confirm_command.returns(true)
          stub_request(:post, %r{apps/example/addons/my_addon$}).
            to_return(response_that_requires_confirmation).then.
            to_return({:status => 200})

          run "addons:add my_addon"
        end

        it "should not continue if the confirmation does not match" do
          Turbot::Command.stub(:current_options).and_return(:confirm => 'not_example')

          lambda do
            Turbot::Command.confirm_command('example')
          end.should raise_error(Turbot::Command::CommandFailed)
        end

        it "should not continue if the user doesn't confirm" do
          stub(Turbot::Command).confirm_command.returns(false)
          stub_request(:post, %r{apps/example/addons/my_addon$}).
            to_return(response_that_requires_confirmation).then.
            to_raise(Turbot::Command::CommandFailed)

          run "addons:add my_addon"
        end
      end
    end
  end

  describe "parsing errors" do
    it "extracts error messages from response when available in XML" do
      Turbot::Command.extract_error('<errors><error>Invalid app name</error></errors>').should == 'Invalid app name'
    end

    it "extracts error messages from response when available in JSON" do
      Turbot::Command.extract_error("{\"error\":\"Invalid app name\"}").should == 'Invalid app name'
    end

    it "extracts error messages from response when available in plain text" do
      response = FakeResponse.new(:body => "Invalid app name", :headers => { :content_type => "text/plain; charset=UTF8" })
      Turbot::Command.extract_error(response).should == 'Invalid app name'
    end

    it "shows Internal Server Error when the response doesn't contain a XML or JSON" do
      Turbot::Command.extract_error('<h1>HTTP 500</h1>').should == "Internal server error.\nRun `turbot status` to check for known platform issues."
    end

    it "shows Internal Server Error when the response is not plain text" do
      response = FakeResponse.new(:body => "Foobar", :headers => { :content_type => "application/xml" })
      Turbot::Command.extract_error(response).should == "Internal server error.\nRun `turbot status` to check for known platform issues."
    end

    it "allows a block to redefine the default error" do
      Turbot::Command.extract_error("Foobar") { "Ok!" }.should == 'Ok!'
    end

    it "doesn't format the response if set to raw" do
      Turbot::Command.extract_error("Foobar", :raw => true) { "Ok!" }.should == 'Ok!'
    end

    it "handles a nil body in parse_error_xml" do
      lambda { Turbot::Command.parse_error_xml(nil) }.should_not raise_error
    end

    it "handles a nil body in parse_error_json" do
      lambda { Turbot::Command.parse_error_json(nil) }.should_not raise_error
    end
  end

  it "correctly resolves commands" do
    class Turbot::Command::Test; end
    class Turbot::Command::Test::Multiple; end

    require "turbot/command/help"
    require "turbot/command/apps"

    Turbot::Command.parse("unknown").should be_nil
    Turbot::Command.parse("list").should include(:klass => Turbot::Command::Apps, :method => :index)
    Turbot::Command.parse("apps").should include(:klass => Turbot::Command::Apps, :method => :index)
    Turbot::Command.parse("apps:create").should include(:klass => Turbot::Command::Apps, :method => :create)
  end

  context "help" do
    it "works as a prefix" do
      turbot("help ps:scale").should =~ /scale dynos by/
    end

    it "works as an option" do
      turbot("ps:scale -h").should =~ /scale dynos by/
      turbot("ps:scale --help").should =~ /scale dynos by/
    end
  end

  context "when no commands match" do

    it "displays the version if --version is used" do
      turbot("--version").should == <<-STDOUT
#{Turbot.user_agent}
STDOUT
    end

    it "suggests similar commands if there are any" do
      original_stderr, original_stdout = $stderr, $stdout
      $stderr = captured_stderr = StringIO.new
      $stdout = captured_stdout = StringIO.new
      begin
        execute("aps")
      rescue SystemExit
      end
      captured_stderr.string.should == <<-STDERR
 !    `aps` is not a turbot command.
 !    Perhaps you meant `apps` or `ps`.
 !    See `turbot help` for a list of available commands.
STDERR
      captured_stdout.string.should == ""
      $stderr, $stdout = original_stderr, original_stdout
    end

    it "does not suggest similar commands if there are none" do
      original_stderr, original_stdout = $stderr, $stdout
      $stderr = captured_stderr = StringIO.new
      $stdout = captured_stdout = StringIO.new
      begin
        execute("sandwich")
      rescue SystemExit
      end
      captured_stderr.string.should == <<-STDERR
 !    `sandwich` is not a turbot command.
 !    See `turbot help` for a list of available commands.
STDERR
      captured_stdout.string.should == ""
      $stderr, $stdout = original_stderr, original_stdout
    end

  end
end
