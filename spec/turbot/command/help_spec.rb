require 'spec_helper'
require 'turbot/command/help'

describe Turbot::Command::Help do

  describe 'help' do
    it 'shows root help' do
      %w(help -h --help).each do |command|
        stderr, stdout = execute(command)
        expect(stderr).to eq('')
        expect(stdout).to include('Usage: turbot COMMAND [--bot APP] [command-specific-options]')
        expect(stdout).to include('auth')
        expect(stdout).to include('help')
      end
    end

    it 'shows command help and namespace help' do
      stderr, stdout = execute('help bots')
      expect(stderr).to eq('')
      expect(stdout).to include('turbot bots')
      expect(stdout).to include('Additional commands')
      expect(stdout).to include('bots:info')
    end

    it 'shows command help' do
      stderr, stdout = execute('help bots:info')
      expect(stderr).to eq('')
      expect(stdout).to include('turbot bots:info')
      expect(stdout).not_to include('Additional commands')
    end

    it 'shows aliased command help' do
      stderr, stdout = execute('help info')
      expect(stderr).to eq('')
      expect(stdout).to include('Alias: info redirects to bots:info')
      expect(stdout).to include('turbot bots:info')
      expect(stdout).not_to include('Additional commands')
    end

    it 'displays an error message if the command does not exist' do
      stderr, stdout = execute('help sudo:sandwich')
      expect(stdout).to eq('')
      expect(stderr).to eq <<-STDERR
 !    sudo:sandwich is not a turbot command. See `turbot help`.
STDERR
    end
  end
end
