require "spec_helper"
require "turbot/command/version"

module Turbot::Command
  describe Version do

    it "shows version info" do
      stderr, stdout = execute("version")
      expect(stderr).to eq("")
      expect(stdout).to eq <<-STDOUT
#{Turbot.user_agent}
STDOUT
    end

  end
end
