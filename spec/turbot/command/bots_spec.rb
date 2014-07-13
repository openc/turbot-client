require "spec_helper"
require "turbot/command/bots"

describe Turbot::Command::Bots do
  describe "validate" do
    before do
      config = {
        'bot_id' => 'dummy bot',
        'data_type' => 'dummy',
        'identifying_fields' => ['name'],
        'files' => 'scraper.rb',
      }
      Turbot::Command::Bots.any_instance.stub(:parsed_manifest).and_return(config)
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

      context "for bot that doesn't output identifying fields" do
        it "says bot is invalid" do
          Turbot::Command::Bots.any_instance.
            stub(:run_scraper_each_line).
            and_yield({title: 'One'}.to_json)

          stderr, stdout = execute("bots:validate")

          stdout.should == ""
          stderr.should include 'No value provided for identifying fields'
        end
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

    context "for bot with manifest missing some required fields" do
      it "says bot is invalid" do
        config = {
          'bot_id' => 'dummy bot',
          'identifying_fields' => ['name'],
          'files' => 'scraper.rb',
        }
        Turbot::Command::Bots.any_instance.stub(:parsed_manifest).and_return(config)

        stderr, stdout = execute("bots:validate")

        stdout.should == ""
        stderr.should include 'Manifest is missing data_type'
      end
    end
  end

  describe '#create_zip_archive' do
    it 'adds all given files to archive' do
      dirs = ['a', 'b', 'a/p', 'b/p']
      paths = ['a/p/x', 'a/y', 'b/p/x', 'b/y', 'z']

      base_dir = Dir.mktmpdir
      dirs.each {|dir| Dir.mkdir(File.join(base_dir, dir))}
      paths.each {|path| FileUtils.touch(File.join(base_dir, path))}

      command = Turbot::Command::Bots.new
      archive_path = Tempfile.new('test').path
      command.send(:create_zip_archive, archive_path, base_dir, ['a', 'b/p/x', 'b/y', 'z'])

      Zip::File.open(archive_path) do |zipfile|
        expect(zipfile.map {|entry| entry.to_s}).to match_array(paths + ['a/p/'])
      end
    end
  end
end
