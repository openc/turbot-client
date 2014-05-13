require "spec_helper"
require "turbot/command/apps"
require "turbot/api"

module Turbot::Command
  describe Apps do

    before(:each) do
      stub_core
    end

    context("info") do

      before(:each) do
        api.post_app("name" => "example", "stack" => "cedar")
        Turbot::API.any_instance.stub(:get_app).and_return(
          "last_run_status" =>       "failed",
          "last_run_ended" =>   "2016/01/01",
          "git_url" =>   "frob",
          "repo_size" =>   123,
          "name" => "example"
        )
      end

      after(:each) do
        api.delete_app("example")
      end

      it "displays impicit app info" do
        stderr, stdout = execute("apps:info")
        stderr.should == ""
        stdout.should == <<-STDOUT
=== example
Git URL:         frob
Last run ended:  2016-01-01 00:00 UTC
Last run status: failed
Repo Size:       123
STDOUT
      end

      it "gets explicit app from --app" do
        stderr, stdout = execute("apps:info --app example")
        stderr.should == ""
        stdout.should == <<-STDOUT
=== example
Git URL:         frob
Last run ended:  2016-01-01 00:00 UTC
Last run status: failed
Repo Size:       123
STDOUT
      end

      it "shows shell app info when --shell option is used" do
        stderr, stdout = execute("apps:info --shell")
        stderr.should == ""
        stdout.should == <<-STDOUT
git_url=frob
last_run_ended=2016/01/01
last_run_status=failed
name=example
repo_size=123
STDOUT
      end

    end

    context("index") do

      before(:each) do
        api.post_app("name" => "example", "stack" => "cedar")
      end

      after(:each) do
        api.delete_app("example")
      end

      it "succeeds" do
        stub_core.list.returns([["example", "user"]])
        stderr, stdout = execute("apps")
        stderr.should == ""
        stdout.should == <<-STDOUT
=== Apps
example

STDOUT
      end

    end
  end
end
