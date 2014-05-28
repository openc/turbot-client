require "spec_helper"
require "turbot/command/bots"

describe Turbot::Command::Bots do
  describe "validate" do
    before do
      Turbot::Command::Bots.any_instance.stub(:parsed_manifest).and_return('data_type' => 'dummy')
    end

    context "for data_type with schema" do
      before do
        Turbot::Command::Bots.any_instance.
          stub(:get_schema).
          and_return(File.expand_path('../../../schemas/dummy_schema.json', __FILE__))

      end

      it "says bot is valid if its output matches the schema" do
        Turbot::Command::Bots.any_instance.
          stub(:run_scraper_each_line).
          and_yield({name: 'One'}.to_json)

        stderr, stdout = execute("bots:validate")

        stderr.should == ""
        stdout.should include 'Validated 1 records successfully'
      end

      it "says bot is invalid if its output doesn't match the schema" do
        Turbot::Command::Bots.any_instance.
          stub(:run_scraper_each_line).
          and_yield({name: 123}.to_json)

        stderr, stdout = execute("bots:validate")

        stdout.should == ""
        stderr.should include 'ERRORS'
      end
    end

    context "for data_type without schema" do
      it "says bot is invalid" do
        Turbot::Command::Bots.any_instance.
          stub(:get_schema).
          and_return(nil)

        stderr, stdout = execute("bots:validate")

        stdout.should == ""
        stderr.should include 'No schema found'
      end
    end
  end
end
