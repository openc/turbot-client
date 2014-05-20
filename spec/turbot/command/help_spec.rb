require "spec_helper"
require "turbot/command/bots"
require "turbot/command/help"

describe Turbot::Command::Help do

  describe "help" do
    it "should show root help with no args" do
      stderr, stdout = execute("help")
      stderr.should == ""
      stdout.should include "Usage: turbot COMMAND [--bot APP] [command-specific-options]"
      stdout.should include "bots"
      stdout.should include "help"
    end

    it "should show command help and namespace help when ambigious" do
      stderr, stdout = execute("help bots")
      stderr.should == ""
      stdout.should include "turbot bots"
      stdout.should include "list your bots"
      stdout.should include "Additional commands"
      stdout.should include "bots:info"
    end

    it "should show only command help when not ambiguous" do
      stderr, stdout = execute("help bots:info")
      stderr.should == ""
      stdout.should include "turbot bots:info"
      stdout.should_not include "Additional commands"
    end

    it "should show command help with --help" do
      stderr, stdout = execute("bots:info --help")
      stderr.should == ""
      stdout.should include "Usage: turbot bots:info"
      stdout.should_not include "Additional commands"
    end

    it "should redirect if the command is an alias" do
      stderr, stdout = execute("help list")
      stderr.should == ""
      stdout.should include "Alias: list redirects to bots"
      stdout.should include "Usage: turbot bots"
      stdout.should include "list your bots"
    end

    it "should show if the command does not exist" do
      stderr, stdout = execute("help sudo:sandwich")
      stderr.should == <<-STDERR
 !    sudo:sandwich is not a turbot command. See `turbot help`.
STDERR
      stdout.should == ""
    end

    it "should show help with naked -h" do
      stderr, stdout = execute("-h")
      stderr.should == ""
      stdout.should include "Usage: turbot COMMAND"
    end

    it "should show help with naked --help" do
      stderr, stdout = execute("--help")
      stderr.should == ""
      stdout.should include "Usage: turbot COMMAND"
    end

    describe "with legacy help" do
      require "helper/legacy_help"

      it "displays the legacy group in the namespace list" do
        stderr, stdout = execute("help")
        stderr.should == ""
        stdout.should include "Foo Group"
      end

      it "displays group help" do
        stderr, stdout = execute("help foo")
        stderr.should == ""
        stdout.should include "do a bar to foo"
        stdout.should include "do a baz to foo"
      end

      it "displays legacy command-specific help" do
        stderr, stdout = execute("help foo:bar")
        stderr.should == ""
        stdout.should include "do a bar to foo"
      end
    end
  end
end
