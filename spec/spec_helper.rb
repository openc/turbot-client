require 'rubygems'

require 'simplecov'
SimpleCov.start do
  add_filter 'spec'
end

require 'tmpdir'

require 'rspec'
require 'webmock/rspec'

require 'turbot'
require 'support/dummy_api'

include WebMock::API

def fixture(path, chmod = 0600)
  filename = File.expand_path(File.join('..', 'fixtures', path), __FILE__)
  if File.exist?(filename)
    FileUtils.chmod(chmod, filename)
  end
  filename
end

def open_netrc
  Netrc.read(Netrc.default_path)
end

def write_netrc(data)
  netrc = open_netrc
  netrc['api.http://turbot.opencorporates.com'] = data
  netrc.save
end

def read_netrc
  open_netrc['api.http://turbot.opencorporates.com']
end

def execute(command_line)
  args = command_line.split(' ')
  command = args.shift

  Turbot::Command.load
  object, method = Turbot::Command.prepare_run(command, args)

  allow_any_instance_of(Turbot::Command::Base).to receive(:bot).and_return('example')

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
