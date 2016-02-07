require 'spec_helper'
require 'turbot/command/version'

describe Turbot::Command::Version do
  describe 'version' do
    it 'shows the version' do
      %w(version --version).each do |command|
        stderr, stdout = execute(command)

        expect(stderr).to eq('')
        expect(stdout).to eq <<-STDOUT
#{Turbot.user_agent}
STDOUT
      end
    end
  end
end
