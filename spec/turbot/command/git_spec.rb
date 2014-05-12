require 'spec_helper'
require 'turbot/command/git'

module Turbot::Command
  describe Git do

    before(:each) do
      stub_core
    end

    context("clone") do

      before(:each) do
        api.post_app("name" => "example", "stack" => "cedar")
      end

      after(:each) do
        api.delete_app("example")
      end

      it "clones and adds remote" do
        any_instance_of(Turbot::Command::Git) do |git|
          mock(git).system("git clone -o turbot git@turbot.com:example.git") do
            puts "Cloning into 'example'..."
          end
        end
        stderr, stdout = execute("git:clone example")
        stderr.should == ""
        stdout.should == <<-STDOUT
Cloning from app 'example'...
Cloning into 'example'...
        STDOUT
      end

      it "clones into another dir" do
        any_instance_of(Turbot::Command::Git) do |git|
          mock(git).system("git clone -o turbot git@turbot.com:example.git somedir") do
            puts "Cloning into 'somedir'..."
          end
        end
        stderr, stdout = execute("git:clone example somedir")
        stderr.should == ""
        stdout.should == <<-STDOUT
Cloning from app 'example'...
Cloning into 'somedir'...
        STDOUT
      end

      it "can specify app with -a" do
        any_instance_of(Turbot::Command::Git) do |git|
          mock(git).system("git clone -o turbot git@turbot.com:example.git") do
            puts "Cloning into 'example'..."
          end
        end
        stderr, stdout = execute("git:clone -a example")
        stderr.should == ""
        stdout.should == <<-STDOUT
Cloning from app 'example'...
Cloning into 'example'...
        STDOUT
      end

      it "can specify app with -a and a dir" do
        any_instance_of(Turbot::Command::Git) do |git|
          mock(git).system("git clone -o turbot git@turbot.com:example.git somedir") do
            puts "Cloning into 'somedir'..."
          end
        end
        stderr, stdout = execute("git:clone -a example somedir")
        stderr.should == ""
        stdout.should == <<-STDOUT
Cloning from app 'example'...
Cloning into 'somedir'...
        STDOUT
      end

      it "clones and sets -r remote" do
        any_instance_of(Turbot::Command::Git) do |git|
          mock(git).system("git clone -o other git@turbot.com:example.git") do
            puts "Cloning into 'example'..."
          end
        end
        stderr, stdout = execute("git:clone example -r other")
        stderr.should == ""
        stdout.should == <<-STDOUT
Cloning from app 'example'...
Cloning into 'example'...
        STDOUT
      end

    end

    context("remote") do

      before(:each) do
        api.post_app("name" => "example", "stack" => "cedar")
        FileUtils.mkdir('example')
        FileUtils.chdir('example') { `git init` }
      end

      after(:each) do
        api.delete_app("example")
        FileUtils.rm_rf('example')
      end

      it "adds remote" do
        any_instance_of(Turbot::Command::Git) do |git|
          stub(git).git('remote').returns("origin")
          stub(git).git('remote add turbot git@turbot.com:example.git')
        end
        stderr, stdout = execute("git:remote")
        stderr.should == ""
        stdout.should == <<-STDOUT
Git remote turbot added
        STDOUT
      end

      it "adds -r remote" do
        any_instance_of(Turbot::Command::Git) do |git|
          stub(git).git('remote').returns("origin")
          stub(git).git('remote add other git@turbot.com:example.git')
        end
        stderr, stdout = execute("git:remote -r other")
        stderr.should == ""
        stdout.should == <<-STDOUT
Git remote other added
        STDOUT
      end

      it "skips remote when it already exists" do
        any_instance_of(Turbot::Command::Git) do |git|
          stub(git).git('remote').returns("turbot")
        end
        stderr, stdout = execute("git:remote")
        stderr.should == <<-STDERR
 !    Git remote turbot already exists
STDERR
        stdout.should == ""
      end

    end

  end
end
