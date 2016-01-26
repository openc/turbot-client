require "spec_helper"
require "turbot/client/pgbackups"
require "turbot/helpers"

describe Turbot::Client::Pgbackups do

  include Turbot::Helpers

  let(:path)   { "http://id:password@pgbackups.turbot.com" }
  let(:client) { Turbot::Client::Pgbackups.new path+'/api' }
  let(:transfer_path) { path + '/client/transfers' }

  describe "api" do
    let(:version) { Turbot::Client.version }

    it 'still has a turbot gem version' do
      expect(version).to be
      expect(version.split(/\./).first.to_i).to be >= 0
    end

    it 'includes the turbot gem version' do
      stub_request(:get, transfer_path)
      client.get_transfers
      expect(a_request(:get, transfer_path).with(
        :headers => {'X-Turbot-Gem-Version' => version}
      )).to have_been_made.once
    end
  end

  describe "create transfers" do
    it "sends a request to the client" do
      stub_request(:post, transfer_path).to_return(
        :body => json_encode({"message" => "success"}),
        :status => 200
      )

      client.create_transfer("postgres://from", "postgres://to", "FROMNAME", "TO_NAME")

      expect(a_request(:post, transfer_path)).to have_been_made.once
    end
  end

end
