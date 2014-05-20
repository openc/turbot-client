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

  describe "parsing errors" do
    it "extracts error messages from response when available in XML" do
      Turbot::Command.extract_error('<errors><error>Invalid bot name</error></errors>').should == 'Invalid bot name'
    end

    it "extracts error messages from response when available in JSON" do
      Turbot::Command.extract_error("{\"error\":\"Invalid bot name\"}").should == 'Invalid bot name'
    end

    it "extracts error messages from response when available in plain text" do
      response = FakeResponse.new(:body => "Invalid bot name", :headers => { :content_type => "text/plain; charset=UTF8" })
      Turbot::Command.extract_error(response).should == 'Invalid bot name'
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
    require "turbot/command/bots"

    Turbot::Command.parse("unknown").should be_nil
    Turbot::Command.parse("list").should include(:klass => Turbot::Command::Bots, :method => :index)
    Turbot::Command.parse("bots").should include(:klass => Turbot::Command::Bots, :method => :index)
    Turbot::Command.parse("bots:info").should include(:klass => Turbot::Command::Bots, :method => :info)
  end

  context "help" do
    it "works as a prefix" do
      turbot("help bots:info").should =~ /show detailed bot information/
    end

    it "works as an option" do
      turbot("bots:info -h").should =~ /show detailed bot information/
      turbot("bots:info --help").should =~ /show detailed bot information/
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
        execute("bot")
      rescue SystemExit
      end
      captured_stderr.string.should == <<-STDERR
 !    `bot` is not a turbot command.
 !    Perhaps you meant `bots`.
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
