require 'spec_helper'

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
  }

  describe "parsing errors" do
    it "extracts error messages from response when available in XML" do
      expect(Turbot::Command.extract_error('<errors><error>Invalid bot name</error></errors>')).to eq('Invalid bot name')
    end

    it "extracts error messages from response when available in JSON" do
      expect(Turbot::Command.extract_error("{\"error\":\"Invalid bot name\"}")).to eq('Invalid bot name')
    end

    it "extracts error messages from response when available in plain text" do
      response = FakeResponse.new(:body => "Invalid bot name", :headers => { :content_type => "text/plain; charset=UTF8" })
      expect(Turbot::Command.extract_error(response)).to eq('Invalid bot name')
    end

    it "shows Internal Server Error when the response doesn't contain a XML or JSON" do
      expect(Turbot::Command.extract_error('<h1>HTTP 500</h1>')).to eq("Internal server error.\nRun `turbot status` to check for known platform issues.")
    end

    it "shows Internal Server Error when the response is not plain text" do
      response = FakeResponse.new(:body => "Foobar", :headers => { :content_type => "application/xml" })
      expect(Turbot::Command.extract_error(response)).to eq("Internal server error.\nRun `turbot status` to check for known platform issues.")
    end

    it "allows a block to redefine the default error" do
      expect(Turbot::Command.extract_error("Foobar") { "Ok!" }).to eq('Ok!')
    end

    it "doesn't format the response if set to raw" do
      expect(Turbot::Command.extract_error("Foobar", :raw => true) { "Ok!" }).to eq('Ok!')
    end

    it "handles a nil body in parse_error_xml" do
      expect { Turbot::Command.parse_error_xml(nil) }.not_to raise_error
    end

    it "handles a nil body in parse_error_json" do
      expect { Turbot::Command.parse_error_json(nil) }.not_to raise_error
    end
  end

  it "correctly resolves commands" do
    class Turbot::Command::Test; end
    class Turbot::Command::Test::Multiple; end

    require "turbot/command/help"
    require "turbot/command/bots"

    expect(Turbot::Command.parse("unknown")).to be_nil
    expect(Turbot::Command.parse("list")).to include(:klass => Turbot::Command::Bots, :method => :index)
    expect(Turbot::Command.parse("bots")).to include(:klass => Turbot::Command::Bots, :method => :index)
    expect(Turbot::Command.parse("bots:info")).to include(:klass => Turbot::Command::Bots, :method => :info)
  end

  context "help" do
    it "works as a prefix" do
      expect(turbot("help bots:info")).to match(/show detailed bot information/)
    end

    it "works as an option" do
      expect(turbot("bots:info -h")).to match(/show detailed bot information/)
      expect(turbot("bots:info --help")).to match(/show detailed bot information/)
    end
  end

  context "when no commands match" do

    it "displays the version if --version is used" do
      expect(turbot("--version")).to eq <<-STDOUT
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
      expect(captured_stderr.string).to eq <<-STDERR
 !    `bot` is not a turbot command.
 !    Perhaps you meant `bots`.
 !    See `turbot help` for a list of available commands.
STDERR
      expect(captured_stdout.string).to eq("")
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
      expect(captured_stderr.string).to eq <<-STDERR
 !    `sandwich` is not a turbot command.
 !    See `turbot help` for a list of available commands.
STDERR
      expect(captured_stdout.string).to eq("")
      $stderr, $stdout = original_stderr, original_stdout
    end

  end
end
