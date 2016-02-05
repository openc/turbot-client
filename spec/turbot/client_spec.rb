require "spec_helper"
require "turbot/client"
require "turbot/helpers"
require 'turbot/command'

describe Turbot::Client do
  include Turbot::Helpers

  before do
    @client = Turbot::Client.new(nil, nil)
    @resource = double('turbot rest resource')
    allow(@client).to receive(:extract_warning)
  end

  describe "internal" do
    before do
      @client = Turbot::Client.new(nil, nil)
    end

    it "creates a RestClient resource for making calls" do
      allow(@client).to receive(:host).and_return('turbot.com')
      allow(@client).to receive(:user).and_return('joe@example.com')
      allow(@client).to receive(:password).and_return('secret')

      res = @client.resource('/xyz')

      expect(res.url).to eq('https://api.turbot.com/xyz')
      expect(res.user).to eq('joe@example.com')
      expect(res.password).to eq('secret')
    end

    it "appends the api. prefix to the host" do
      @client.host = "turbot.com"
      expect(@client.resource('/xyz').url).to eq('https://api.turbot.com/xyz')
    end

    it "doesn't add the api. prefix to full hosts" do
      @client.host = 'http://resource'
      res = @client.resource('/xyz')
      expect(res.url).to eq('http://resource/xyz')
    end

    it "runs a callback when the API sets a warning header" do
      response = double('rest client response', :headers => { :x_turbot_warning => 'Warning' })
      expect(@client).to receive(:resource).and_return(@resource)
      expect(@resource).to receive(:get).and_return(response)
      @client.on_warning { |msg| @callback = msg }
      @client.get('test')
      expect(@callback).to eq('Warning')
    end

    it "doesn't run the callback twice for the same warning" do
      response = double('rest client response', :headers => { :x_turbot_warning => 'Warning' })
      allow(@client).to receive(:resource).and_return(@resource)
      allow(@resource).to receive(:get).and_return(response)
      @client.on_warning { |msg| @callback_called ||= 0; @callback_called += 1 }
      @client.get('test1')
      @client.get('test2')
      expect(@callback_called).to eq(1)
    end
  end
end
