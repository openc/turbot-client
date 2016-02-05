require 'spec_helper'
require 'turbot/command/help'

describe Turbot::Command::Help do

  describe "help" do
    it "should show root help with no args" do
      stderr, stdout = execute("help")
      expect(stderr).to eq("")
      expect(stdout).to include "Usage: turbot COMMAND [--bot APP] [command-specific-options]"
      expect(stdout).to include "bots"
      expect(stdout).to include "help"
    end

    it "should show command help and namespace help when ambigious" do
      stderr, stdout = execute("help bots")
      expect(stderr).to eq("")
      expect(stdout).to include "turbot bots"
      expect(stdout).to include "list your bots"
      expect(stdout).to include "Additional commands"
      expect(stdout).to include "bots:info"
    end

    it "should show only command help when not ambiguous" do
      stderr, stdout = execute("help bots:info")
      expect(stderr).to eq("")
      expect(stdout).to include "turbot bots:info"
      expect(stdout).not_to include "Additional commands"
    end

    it "should show command help with --help" do
      stderr, stdout = execute("bots:info --help")
      expect(stderr).to eq("")
      expect(stdout).to include "Usage: turbot bots:info"
      expect(stdout).not_to include "Additional commands"
    end

    it "should redirect if the command is an alias" do
      stderr, stdout = execute("help list")
      expect(stderr).to eq("")
      expect(stdout).to include "Alias: list redirects to bots"
      expect(stdout).to include "Usage: turbot bots"
      expect(stdout).to include "list your bots"
    end

    it "should show if the command does not exist" do
      stderr, stdout = execute("help sudo:sandwich")
      expect(stderr).to eq <<-STDERR
 !    sudo:sandwich is not a turbot command. See `turbot help`.
STDERR
      expect(stdout).to eq("")
    end

    it "should show help with naked -h" do
      stderr, stdout = execute("-h")
      expect(stderr).to eq("")
      expect(stdout).to include "Usage: turbot COMMAND"
    end

    it "should show help with naked --help" do
      stderr, stdout = execute("--help")
      expect(stderr).to eq("")
      expect(stdout).to include "Usage: turbot COMMAND"
    end
  end
end
