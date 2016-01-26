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

def org_api
  Turbot::Client::Organizations.api(:mock => true)
end

def stub_api_request(method, path)
  stub_request(method, "http://turbot.opencorporates.com#{path}")
end

def prepare_command(klass)
  command = klass.new
  command.stub(:bot).and_return("example")
  command.stub(:ask).and_return("")
  command.stub(:display)
  command.stub(:hputs)
  command.stub(:hprint)
  command.stub(:turbot).and_return(double('turbot client', :host => 'turbot.com'))
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

  stub(Turbot::Auth).get_credentials.returns(['email@example.com', 'apikey01'])
  stub(Turbot::Auth).api_key.returns('apikey01')

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

def stub_core
  @stubbed_core ||= begin
    stubbed_core = nil
    any_instance_of(Turbot::Client) do |core|
      stubbed_core = stub(core)
    end
    stub(Turbot::Auth).user.returns("email@example.com")
    stub(Turbot::Auth).password.returns("pass")
    stub(Turbot::Client).auth.returns("apikey01")
    stubbed_core
  end
end

def stub_pg
  @stubbed_pg ||= begin
    stubbed_pg = nil
    any_instance_of(Turbot::Client::TurbotPostgresql) do |pg|
      stubbed_pg = stub(pg)
    end
    stubbed_pg
  end
end

def stub_pgbackups
  @stubbed_pgbackups ||= begin
    stubbed_pgbackups = nil
    any_instance_of(Turbot::Client::Pgbackups) do |pgbackups|
      stubbed_pgbackups = stub(pgbackups)
    end
    stubbed_pgbackups
  end
end

def stub_rendezvous
  @stubbed_rendezvous ||= begin
    stubbed_rendezvous = nil
    any_instance_of(Turbot::Client::Rendezvous) do |rendezvous|
      stubbed_rendezvous = stub(rendezvous)
    end
    stubbed_rendezvous
  end
end

def stub_cisaurus
  @stub_cisaurus ||= begin
    stub_cisaurus = nil
    any_instance_of(Turbot::Client::Cisaurus) do |cisaurus|
      stub_cisaurus = stub(cisaurus)
    end
    stub_cisaurus
  end
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

module SandboxHelper
  def bash(cmd)
    `#{cmd}`
  end
end

require "turbot/helpers"
module Turbot::Helpers
  @home_directory = Dir.mktmpdir
  undef_method :home_directory
  def home_directory
    @home_directory
  end
end

require "support/display_message_matcher"
require "support/organizations_mock_helper"
require "support/dummy_api"

RSpec.configure do |config|
  config.color = true
  config.include DisplayMessageMatcher
  config.order = 'rand'
  config.before { Turbot::Helpers.error_with_failure = false }
  config.after { RR.reset }
end
