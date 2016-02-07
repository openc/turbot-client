require 'spec_helper'

describe Turbot::Command::Base do
  before do
    allow(subject).to receive(:display)
    @client = double('turbot client', :host => 'turbot.com')
  end

  context 'detecting the bot' do
    it 'attempts to find the bot via the --bot option' do
      allow(subject).to receive(:options).and_return(:bot => 'example')
      expect(subject.bot).to eq('example')
    end

    it 'attempts to find the bot via TURBOT_BOT when not explicitly specified' do
      ENV['TURBOT_BOT'] = 'myenvapp'
      expect(subject.bot).to eq('myenvapp')
      allow(subject).to receive(:options).and_return([])
      expect(subject.bot).to eq('myenvapp')
      ENV.delete('TURBOT_BOT')
    end

    it 'overrides TURBOT_BOT when explicitly specified' do
      ENV['TURBOT_BOT'] = 'myenvapp'
      allow(subject).to receive(:options).and_return(:bot => 'example')
      expect(subject.bot).to eq('example')
      ENV.delete('TURBOT_BOT')
    end
  end
end
