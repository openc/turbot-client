require 'spec_helper'
require 'turbot/command/version'

module Turbot::Command
  describe Version do
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
