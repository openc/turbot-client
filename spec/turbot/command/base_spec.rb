require "spec_helper"
require "turbot/command/base"

module Turbot::Command
  describe Base do
    before do
      @base = Base.new
      allow(@base).to receive(:display)
      @client = double('turbot client', :host => 'turbot.com')
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
