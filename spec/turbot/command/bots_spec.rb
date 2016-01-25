require "spec_helper"
require "turbot/command/bots"

describe Turbot::Command::Bots do
  include Turbot::Helpers

  describe "validate" do
    let :working_directory do
      Dir.mktmpdir
    end

    let :schemas_directory do
      Dir.mktmpdir
    end

    before do
      config = {
        'bot_id' => 'dummy_bot',
        'data_type' => 'dummy',
        'identifying_fields' => ['name'],
        'files' => 'scraper.rb',
        'language' => 'ruby',
        'publisher' => {
          'name' => 'Dummy',
          'url' => 'http://example.com/',
          'terms' => 'MIT',
          'terms_url' => 'http://opensource.org/licenses/MIT',
        },
      }
      Turbot::Command::Bots.any_instance.stub(:parsed_manifest).and_return(config)

      # Create a manifest.json file for TurbotRunner to find.
      File.open(File.join(working_directory, 'manifest.json'), 'w') { |f| f << JSON.dump(config) }
      Turbot::Command::Bots.any_instance.stub(:working_directory).and_return(working_directory)

      # Change the path to TurbotRunner's schemas.
      begin
        old_verbose, $VERBOSE = $VERBOSE, nil
        TurbotRunner::SCHEMAS_PATH = File.expand_path('../../../schemas', __FILE__)
      ensure
        $VERBOSE = old_verbose
      end
    end

    after do
      FileUtils.remove_entry_secure(working_directory)
      FileUtils.remove_entry_secure(schemas_directory)
    end

    def define_scraper(hash)
      File.open(File.join(working_directory, 'scraper.rb'), 'w') do |f|
        f << <<-EOL
require 'json'
puts JSON.dump(#{hash})
        EOL
      end
    end

    describe "#info" do
      it "should succeed" do
        stub_api_request(:get, "/api/bots/example?api_key=apikey01").to_return({
          :body => json_encode({
            "data" => {
              "bot_id" => "dummy_bot",
              "created_at" => "2010-01-01T00:00:00.000Z",
              "updated_at" => "2010-01-02T00:00:00.000Z",
              "state" => "scheduled",
            }
          })
        })

        expect{ execute("bots:info") }.to_not raise_error
      end
    end

    context "for data_type with schema" do
      it "says bot is valid if its output matches the schema" do
        define_scraper(name: 'One')

        stderr, stdout = execute("bots:validate")

        stdout.should include 'Validated 1 records!'
        stderr.should == ""
      end

      it "says bot is invalid if its output doesn't match the schema" do
        define_scraper(name: 123)

        stderr, stdout = execute("bots:validate")

        stdout.should include 'Property of wrong type'
        stderr.should == ""
      end

      context "for bot that doesn't output identifying fields" do
        it "says bot is invalid" do
          define_scraper(title: 'One')

          stderr, stdout = execute("bots:validate")

          stdout.should include 'There were no values provided for any of the identifying fields'
          stderr.should == ""
        end
      end
    end

    context "for data_type without schema" do
      it "says bot is invalid" do
        define_scraper({})

        stderr, stdout = execute("bots:validate")

        stdout.should include "Validated 0 records before bot failed!"
        stderr.should == ""
      end
    end

    context "for bot with manifest missing some required fields" do
      it "says bot is invalid" do
        config = {
          'bot_id' => 'dummy_bot',
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
