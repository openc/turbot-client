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
      Turbot::Auth.stub(:api_key).and_return('apikey01')

      stderr, stdout = execute("auth:token")
      stderr.should == ""
      stdout.should == <<-STDOUT
apikey01
STDOUT
    end

    it "displays the user's api key" do
      Turbot::Auth.stub(:api_key).and_return(nil)

      stderr, stdout = execute("auth:token")
      stderr.should == ""
      stdout.should == <<-STDOUT
apikey01
STDOUT
    end
  end

  describe "auth:whoami" do
    it "displays the user's email address" do
      Turbot::Auth.stub(:read_credentials).and_return(['email@example.com', 'apikey01'])

      stderr, stdout = execute("auth:whoami")
      stderr.should == ""
      stdout.should == <<-STDOUT
email@example.com
STDOUT
    end

    it "displays a message if not logged in" do
      Turbot::Auth.stub(:read_credentials).and_return(false)

      stderr, stdout = execute("auth:whoami")
      stdout.should == ""
      stderr.should == <<-STDERR
 !    not logged in
STDERR
    end

  end

end
