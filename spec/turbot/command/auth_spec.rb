require "spec_helper"
require "turbot/command/auth"

describe Turbot::Command::Auth do
  describe "auth" do
    it "displays turbot help auth" do
      stderr, stdout = execute("auth")

      stderr.should == ""
      stdout.should include "Additional commands"
      stdout.should include "auth:login"
      stdout.should include "auth:logout"
    end
  end

  describe "auth:token" do

    it "displays the user's api key" do
      stderr, stdout = execute("auth:token")
      stderr.should == ""
      stdout.should == <<-STDOUT
apikey01
STDOUT
    end
  end

  describe "auth:whoami" do
    it "displays the user's email address" do
      stderr, stdout = execute("auth:whoami")
      stderr.should == ""
      stdout.should == <<-STDOUT
email@example.com
STDOUT
    end

  end

end
