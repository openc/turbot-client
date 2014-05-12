require "spec_helper"
require "turbot/command/base"

module Turbot::Command
  describe Base do
    before do
      @base = Base.new
      @base.stub!(:display)
      @client = mock('turbot client', :host => 'turbot.com')
    end

    describe "confirming" do
      it "confirms the app via --confirm" do
        Turbot::Command.stub(:current_options).and_return(:confirm => "example")
        @base.stub(:app).and_return("example")
        @base.confirm_command.should be_true
      end

      it "does not confirms the app via --confirm on a mismatch" do
        Turbot::Command.stub(:current_options).and_return(:confirm => "badapp")
        @base.stub(:app).and_return("example")
        lambda { @base.confirm_command}.should raise_error CommandFailed
      end

      it "confirms the app interactively via ask" do
        @base.stub(:app).and_return("example")
        @base.stub(:ask).and_return("example")
        Turbot::Command.stub(:current_options).and_return({})
        @base.confirm_command.should be_true
      end

      it "fails if the interactive confirm doesn't match" do
        @base.stub(:app).and_return("example")
        @base.stub(:ask).and_return("badresponse")
        Turbot::Command.stub(:current_options).and_return({})
        capture_stderr do
          lambda { @base.confirm_command }.should raise_error(SystemExit)
        end.should == <<-STDERR
 !    Confirmation did not match example. Aborted.
STDERR
      end
    end

    context "detecting the app" do
      it "attempts to find the app via the --app option" do
        @base.stub!(:options).and_return(:app => "example")
        @base.app.should == "example"
      end

      it "attempts to find the app via TURBOT_APP when not explicitly specified" do
        ENV['TURBOT_BOT'] = "myenvapp"
        @base.app.should == "myenvapp"
        @base.stub!(:options).and_return([])
        @base.app.should == "myenvapp"
        ENV.delete('TURBOT_APP')
      end

      it "overrides TURBOT_APP when explicitly specified" do
        ENV['TURBOT_BOT'] = "myenvapp"
        @base.stub!(:options).and_return(:app => "example")
        @base.app.should == "example"
        ENV.delete('TURBOT_APP')
      end
    end
  end
end
