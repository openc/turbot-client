require "spec_helper"
require "turbot/command/auth"

describe Turbot::Command::Auth do
  describe "auth" do
    it "displays turbot help auth" do
      stderr, stdout = execute("auth")

      expect(stderr).to eq("")
      expect(stdout).to include "Additional commands"
      expect(stdout).to include "auth:login"
      expect(stdout).to include "auth:logout"
    end
  end

  describe "auth:token" do

    it "displays the user's api key" do
      allow(Turbot::Auth).to receive(:api_key).and_return('apikey01')

      stderr, stdout = execute("auth:token")
      expect(stderr).to eq("")
      expect(stdout).to eq <<-STDOUT
apikey01
STDOUT
    end

    it "displays the user's api key" do
      allow(Turbot::Auth).to receive(:api_key).and_return(nil)

      stderr, stdout = execute("auth:token")
      expect(stderr).to eq("")
      expect(stdout).to eq <<-STDOUT
apikey01
STDOUT
    end
  end

  describe "auth:whoami" do
    it "displays the user's email address" do
      allow(Turbot::Auth).to receive(:read_credentials).and_return(['email@example.com', 'apikey01'])

      stderr, stdout = execute("auth:whoami")
      expect(stderr).to eq("")
      expect(stdout).to eq <<-STDOUT
email@example.com
STDOUT
    end

    it "displays a message if not logged in" do
      allow(Turbot::Auth).to receive(:read_credentials).and_return(false)

      stderr, stdout = execute("auth:whoami")
      expect(stdout).to eq("")
      expect(stderr).to eq <<-STDERR
 !    not logged in
STDERR
    end

  end

end
