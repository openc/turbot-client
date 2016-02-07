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
    it "extracts error messages from response when available in JSON" do
      expect(Turbot::Command.extract_error("{\"message\":\"Invalid bot name\"}")).to eq('Invalid bot name')
    end

    it "shows Internal Server Error when the response doesn't contain a XML or JSON" do
      expect(Turbot::Command.extract_error('<h1>HTTP 500</h1>')).to eq("Internal server error")
    end

    it "shows Internal Server Error when the response is not plain text" do
      response = FakeResponse.new(:body => "Foobar", :headers => { :content_type => "application/xml" })
      expect(Turbot::Command.extract_error(response)).to eq("Internal server error")
    end

    it "allows a block to redefine the default error" do
      expect(Turbot::Command.extract_error("Foobar") { "Ok!" }).to eq('Ok!')
    end

    it "doesn't format the response if set to raw" do
      expect(Turbot::Command.extract_error("Foobar", :raw => true) { "Ok!" }).to eq('Ok!')
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

  context "when no commands match" do
    it "suggests similar commands if there are any" do
      stderr, stdout = execute("bot")
      expect(stderr).to eq <<-STDERR
 !    `bot` is not a turbot command.
 !    Perhaps you meant `bots`.
 !    See `turbot help` for a list of available commands.
STDERR
      expect(stdout).to eq("")
    end

    it "does not suggest similar commands if there are none" do
      stderr, stdout = execute("sandwich")
      expect(stderr).to eq <<-STDERR
 !    `sandwich` is not a turbot command.
 !    See `turbot help` for a list of available commands.
STDERR
      expect(stdout).to eq("")
    end

  end
end
