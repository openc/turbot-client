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
  before do
    Turbot::Command.load
  end

  it 'shows command help if parse error on command option' do
    stderr, stdout = execute('bots:generate -l')
    expect(stderr).to eq('')
    expect(stdout).to include('turbot bots:generate')
    expect(stdout).not_to include('Additional commands')
  end

  it 'shows command help if one invalid argument' do
    stderr, stdout = execute('version foo')
    expect(stdout).to include('turbot version')
    expect(stdout).not_to include('Additional commands')
    expect(stderr).to eq <<-STDERR
 !    Invalid argument: "foo"
STDERR
  end

  it 'shows command help if many invalid arguments' do
    stderr, stdout = execute('version foo bar baz')
    expect(stdout).to include('turbot version')
    expect(stdout).not_to include('Additional commands')
    expect(stderr).to eq <<-STDERR
 !    Invalid arguments: "foo", "bar" and "baz"
STDERR
  end

  describe 'parsing errors' do
    it 'extracts error messages from response when available in JSON' do
      expect(Turbot::Command.extract_error('{"message":"Invalid bot name"}')).to eq('Invalid bot name')
    end

    it "shows Internal Server Error when the response doesn't contain a XML or JSON" do
      expect(Turbot::Command.extract_error('<h1>HTTP 500</h1>')).to eq('Internal server error')
    end

    it 'shows Internal Server Error when the response is not plain text' do
      response = FakeResponse.new(:body => 'Foobar', :headers => { :content_type => 'application/xml' })
      expect(Turbot::Command.extract_error(response)).to eq('Internal server error')
    end

    it 'allows a block to redefine the default error' do
      expect(Turbot::Command.extract_error('Foobar') { 'Ok!' }).to eq('Ok!')
    end

    it "doesn't format the response if set to raw" do
      expect(Turbot::Command.extract_error('Foobar', :raw => true) { 'Ok!' }).to eq('Ok!')
    end
  end

  context 'when no commands match' do
    it 'suggests one command' do
      stderr, stdout = execute('bot')
      expect(stderr).to eq <<-STDERR
 !    `bot` is not a turbot command.
 !    Perhaps you meant `bots`.
 !    See `turbot help` for a list of available commands.
STDERR
      expect(stdout).to eq('')
    end

    it 'suggests many commands' do
      stderr, stdout = execute('hefo')
      expect(stderr).to eq <<-STDERR
 !    `hefo` is not a turbot command.
 !    Perhaps you meant `help` or `info`.
 !    See `turbot help` for a list of available commands.
STDERR
      expect(stdout).to eq('')
    end

    it 'does not suggest similar commands if there are none' do
      stderr, stdout = execute('sandwich')
      expect(stderr).to eq <<-STDERR
 !    `sandwich` is not a turbot command.
 !    See `turbot help` for a list of available commands.
STDERR
      expect(stdout).to eq('')
    end

  end
end
