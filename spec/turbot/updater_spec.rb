require "spec_helper"
require "turbot/updater"
require "turbot/version"

module Turbot
  describe Updater do

    it "calculates the latest local version" do
      Turbot::Updater.latest_local_version.should == Turbot::VERSION
    end

    it "calculates compare_versions" do
      Turbot::Updater.compare_versions('1.1.1', '1.1.1').should == 0

      Turbot::Updater.compare_versions('2.1.1', '1.1.1').should == 1
      Turbot::Updater.compare_versions('1.1.1', '2.1.1').should == -1

      Turbot::Updater.compare_versions('1.2.1', '1.1.1').should == 1
      Turbot::Updater.compare_versions('1.1.1', '1.2.1').should == -1

      Turbot::Updater.compare_versions('1.1.2', '1.1.1').should == 1
      Turbot::Updater.compare_versions('1.1.1', '1.1.2').should == -1

      Turbot::Updater.compare_versions('2.1.1', '1.2.1').should == 1
      Turbot::Updater.compare_versions('1.2.1', '2.1.1').should == -1

      Turbot::Updater.compare_versions('2.1.1', '1.1.2').should == 1
      Turbot::Updater.compare_versions('1.1.2', '2.1.1').should == -1

      Turbot::Updater.compare_versions('1.2.4', '1.2.3').should == 1
      Turbot::Updater.compare_versions('1.2.3', '1.2.4').should == -1

      Turbot::Updater.compare_versions('1.2.1', '1.2'  ).should == 1
      Turbot::Updater.compare_versions('1.2',   '1.2.1').should == -1

      Turbot::Updater.compare_versions('1.1.1.pre1', '1.1.1').should == 1
      Turbot::Updater.compare_versions('1.1.1', '1.1.1.pre1').should == -1

      Turbot::Updater.compare_versions('1.1.1.pre2', '1.1.1.pre1').should == 1
      Turbot::Updater.compare_versions('1.1.1.pre1', '1.1.1.pre2').should == -1
    end

  end
end
