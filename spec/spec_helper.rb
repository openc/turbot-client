$stdin = File.new("/dev/null")

require "rubygems"

require "simplecov"
require "coveralls"
SimpleCov.formatter = Coveralls::SimpleCov::Formatter
SimpleCov.start do
  add_filter "spec"
end

require "excon"
Excon.defaults[:mock] = true

# ensure these are around for errors
# as their require is generally deferred
#require "turbot-api"
require "rest_client"

require "turbot/cli"
require "rspec"
require "rr"
require "fakefs/safe"
require 'tmpdir'
require "webmock/rspec"

include WebMock::API

WebMock::HttpLibAdapters::ExconAdapter.disable!

def api
  Turbot::API.new(:api_key => "pass", :mock => true)
end

def stub_api_request(method, path)
  stub_request(method, "http://turbot.opencorporates.com#{path}")
end

def prepare_command(klass)
  command = klass.new
  allow(command).to receive(:bot).and_return("example")
  allow(command).to receive(:ask).and_return("")
  allow(command).to receive(:display)
  allow(command).to receive(:hputs)
  allow(command).to receive(:turbot).and_return(double('turbot client', :host => 'turbot.com'))
  command
end

def execute(command_line)
  extend RR::Adapters::RRMethods

  args = command_line.split(" ")
  command = args.shift

  Turbot::Command.load
  object, method = Turbot::Command.prepare_run(command, args)

  any_instance_of(Turbot::Command::Base) do |base|
    stub(base).bot.returns("example")
  end

  original_stdin, original_stderr, original_stdout = $stdin, $stderr, $stdout

  $stdin  = captured_stdin  = StringIO.new
  $stderr = captured_stderr = StringIO.new
  $stdout = captured_stdout = StringIO.new
  class << captured_stdout
    def tty?
      true
    end
  end

  begin
    object.send(method)
  rescue SystemExit
  ensure
    $stdin, $stderr, $stdout = original_stdin, original_stderr, original_stdout
    Turbot::Command.current_command = nil
  end

  [captured_stderr.string, captured_stdout.string]
end

def any_instance_of(klass, &block)
  extend RR::Adapters::RRMethods
  any_instance_of(klass, &block)
end

def run(command_line)
  capture_stdout do
    begin
      Turbot::CLI.start(*command_line.split(" "))
    rescue SystemExit
    end
  end
end

alias turbot run

def capture_stderr(&block)
  original_stderr = $stderr
  $stderr = captured_stderr = StringIO.new
  begin
    yield
  ensure
    $stderr = original_stderr
  end
  captured_stderr.string
end

def capture_stdout(&block)
  original_stdout = $stdout
  $stdout = captured_stdout = StringIO.new
  begin
    yield
  ensure
    $stdout = original_stdout
  end
  captured_stdout.string
end

def fail_command(message)
  raise_error(Turbot::Command::CommandFailed, message)
end

def with_blank_git_repository(&block)
  sandbox = File.join(Dir.tmpdir, "turbot", Process.pid.to_s)
  FileUtils.mkdir_p(sandbox)

  old_dir = Dir.pwd
  Dir.chdir(sandbox)

  `git init`
  block.call

  FileUtils.rm_rf(sandbox)
ensure
  Dir.chdir(old_dir)
end

require "support/dummy_api"

RSpec.configure do |config|
  config.color = true
  config.order = 'rand'
  config.before { Turbot::Helpers.error_with_failure = false }
  config.after { RR.reset }
end
