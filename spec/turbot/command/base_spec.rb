require "spec_helper"
require "turbot/command/base"

module Turbot::Command
  describe Base do
    before do
      @base = Base.new
      @base.stub(:display)
      @client = double('turbot client', :host => 'turbot.com')
    end

    describe "confirming" do
      it "confirms the bot via --confirm" do
        Turbot::Command.stub(:current_options).and_return(:confirm => "example")
        @base.stub(:bot).and_return("example")
        @base.confirm_command.should eq(true)
      end

      it "does not confirms the bot via --confirm on a mismatch" do
        Turbot::Command.stub(:current_options).and_return(:confirm => "badapp")
        @base.stub(:bot).and_return("example")
        lambda { @base.confirm_command}.should raise_error CommandFailed
      end

      it "confirms the bot interactively via ask" do
        @base.stub(:bot).and_return("example")
        @base.stub(:ask).and_return("example")
        Turbot::Command.stub(:current_options).and_return({})
        @base.confirm_command.should eq(true)
      end

      it "fails if the interactive confirm doesn't match" do
        @base.stub(:bot).and_return("example")
        @base.stub(:ask).and_return("badresponse")
        Turbot::Command.stub(:current_options).and_return({})
        capture_stderr do
          lambda { @base.confirm_command }.should raise_error(SystemExit)
        end.should == <<-STDERR
 !    Confirmation did not match example. Aborted.
STDERR
      end
    end

    context "detecting the bot" do
      it "attempts to find the bot via the --bot option" do
        @base.stub(:options).and_return(:bot => "example")
        @base.bot.should == "example"
      end

      it "attempts to find the bot via TURBOT_BOT when not explicitly specified" do
        ENV['TURBOT_BOT'] = "myenvapp"
        @base.bot.should == "myenvapp"
        @base.stub(:options).and_return([])
        @base.bot.should == "myenvapp"
        ENV.delete('TURBOT_BOT')
      end

      it "overrides TURBOT_BOT when explicitly specified" do
        ENV['TURBOT_BOT'] = "myenvapp"
        @base.stub(:options).and_return(:bot => "example")
        @base.bot.should == "example"
        ENV.delete('TURBOT_BOT')
      end
    end
  end
end
