require "spec_helper"
require "turbot/command/base"

module Turbot::Command
  describe Base do
    before do
      @base = Base.new
      allow(@base).to receive(:display)
      @client = double('turbot client', :host => 'turbot.com')
    end

    describe "confirming" do
      it "confirms the bot via --confirm" do
        allow(Turbot::Command).to receive(:current_options).and_return(:confirm => "example")
        allow(@base).to receive(:bot).and_return("example")
        expect(@base.confirm_command).to eq(true)
      end

      it "does not confirms the bot via --confirm on a mismatch" do
        allow(Turbot::Command).to receive(:current_options).and_return(:confirm => "badapp")
        allow(@base).to receive(:bot).and_return("example")
        expect { @base.confirm_command}.to raise_error CommandFailed
      end

      it "confirms the bot interactively via ask" do
        allow(@base).to receive(:bot).and_return("example")
        allow(@base).to receive(:ask).and_return("example")
        allow(Turbot::Command).to receive(:current_options).and_return({})
        expect(@base.confirm_command).to eq(true)
      end

      it "fails if the interactive confirm doesn't match" do
        allow(@base).to receive(:bot).and_return("example")
        allow(@base).to receive(:ask).and_return("badresponse")
        allow(Turbot::Command).to receive(:current_options).and_return({})
        expect(capture_stderr do
          expect { @base.confirm_command }.to raise_error(SystemExit)
        end).to eq <<-STDERR
 !    Confirmation did not match example. Aborted.
STDERR
      end
    end

    context "detecting the bot" do
      it "attempts to find the bot via the --bot option" do
        allow(@base).to receive(:options).and_return(:bot => "example")
        expect(@base.bot).to eq("example")
      end

      it "attempts to find the bot via TURBOT_BOT when not explicitly specified" do
        ENV['TURBOT_BOT'] = "myenvapp"
        expect(@base.bot).to eq("myenvapp")
        allow(@base).to receive(:options).and_return([])
        expect(@base.bot).to eq("myenvapp")
        ENV.delete('TURBOT_BOT')
      end

      it "overrides TURBOT_BOT when explicitly specified" do
        ENV['TURBOT_BOT'] = "myenvapp"
        allow(@base).to receive(:options).and_return(:bot => "example")
        expect(@base.bot).to eq("example")
        ENV.delete('TURBOT_BOT')
      end
    end
  end
end
