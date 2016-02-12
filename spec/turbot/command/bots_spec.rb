require 'spec_helper'
require 'turbot/command/bots'
require 'turbot_runner'

describe Turbot::Command::Bots do
  context 'when unauthenticated' do
    before do
      allow(Netrc).to receive(:default_path).and_return(fixture('empty'))
    end

    describe 'bots' do
      it 'lists no bots' do
        stub_request(:get, 'http://turbot.opencorporates.com/api/bots?api_key=').to_return({
          :status => 401,
          :body => JSON.dump('message' => 'No API key provided'),
        })

        stderr, stdout = execute('bots')

        expect(stdout).to eq('')
        expect(stderr).to eq <<-STDERR
 !    No API key provided (HTTP 401)
STDERR
      end
    end
  end

  context 'when authenticated' do
    before do
      allow(Netrc).to receive(:default_path).and_return(fixture('netrc'))
    end

    describe 'bots' do
      it 'lists bots' do
        stub_request(:get, 'http://turbot.opencorporates.com/api/bots?api_key=apikey01').to_return({
          :status => 200,
          :body => JSON.dump({
            'data' => [{
              'bot_id' => 'dummy_bot',
              'created_at' => '2010-01-01T00:00:00.000Z',
              'updated_at' => '2010-01-02T00:00:00.000Z',
              'state' => 'scheduled',
            }],
          }),
        })

        stderr, stdout = execute('bots')

        expect(stderr).to eq('')
        expect(stdout).to eq <<-STDOUT
dummy_bot
STDOUT
      end

      it 'lists no bots' do
        stub_request(:get, 'http://turbot.opencorporates.com/api/bots?api_key=apikey01').to_return({
          :status => 200,
          :body => JSON.dump('data' => []),
        })

        stderr, stdout = execute('bots')

        expect(stderr).to eq('')
        expect(stdout).to eq <<-STDOUT
You have no bots.
STDOUT
      end
    end

    describe 'bots:info' do
      it "shows the given bot's details" do
        stub_bot_info

        stderr, stdout = execute('bots:info --bot example')

        expect(stderr).to eq('')
        expect(stdout).to eq <<-STDOUT
bot_id: dummy_bot
created_at: 2010-01-01T00:00:00.000Z
updated_at: 2010-01-02T00:00:00.000Z
state: scheduled
STDOUT
      end

      it "shows the inferred bot's details" do
        stub_bot_info

        bot_directory = create_bot_directory
        create_manifest_file(bot_directory)

        stderr, stdout = execute_in_directory('bots:info', bot_directory)

        expect(stderr).to eq('')
        expect(stdout).to eq <<-STDOUT
bot_id: dummy_bot
created_at: 2010-01-01T00:00:00.000Z
updated_at: 2010-01-02T00:00:00.000Z
state: scheduled
STDOUT
      end

      it 'errors if no local bot is found' do
        stderr, stdout = execute('bots:info')

        expect(stdout).to eq('')
        expect(stderr).to eq <<-STDERR
 !    No bot specified.
 !    Run this command from a bot directory containing a `manifest.json` file, or specify the bot with --bot BOT.
STDERR
      end

      it 'errors if no bot exists in Turbot' do
        stub_bot_info_error

        stderr, stdout = execute('bots:info --bot example')

        expect(stdout).to eq('')
        expect(stderr).to eq <<-STDERR
 !    No bot registered for bot_id example
 !    If you have renamed your bot, ... (HTTP 402: bot-not-found)
STDERR
      end
    end

    describe 'bots:generate' do
      it 'generates a Ruby bot template' do
        stub_bot_info_error('rb')

        working_directory = Dir.mktmpdir

        stderr, stdout = execute_in_directory('bots:generate --bot rb', working_directory)

        expect(stderr).to eq('')
        expect(stdout).to eq <<-STDOUT
Created new bot template for rb!
STDOUT

        expect(File.exist?(File.join(working_directory, 'rb', 'LICENSE.txt'))).to eq(true)
        expect(File.exist?(File.join(working_directory, 'rb', 'manifest.json'))).to eq(true)
        expect(File.exist?(File.join(working_directory, 'rb', 'scraper.rb'))).to eq(true)
      end

      it 'generates a Python bot template' do
        stub_bot_info_error('py')

        working_directory = Dir.mktmpdir

        stderr, stdout = execute_in_directory('bots:generate --bot py --language python', working_directory)

        expect(stderr).to eq('')
        expect(stdout).to eq <<-STDOUT
Created new bot template for py!
STDOUT

        expect(File.exist?(File.join(working_directory, 'py', 'LICENSE.txt'))).to eq(true)
        expect(File.exist?(File.join(working_directory, 'py', 'manifest.json'))).to eq(true)
        expect(File.exist?(File.join(working_directory, 'py', 'scraper.py'))).to eq(true)
      end

      it 'errors if the bot exists in Turbot' do
        stub_bot_info

        stderr, stdout = execute('bots:generate --bot example')

        expect(stdout).to eq('')
        expect(stderr).to eq <<-STDERR
 !    There's already a bot named example in Turbot. Try another name.
STDERR
      end

      it 'errors if the bot name is invalid' do
        stub_bot_info_error('example!')

        stderr, stdout = execute('bots:generate --bot example!')

        expect(stdout).to eq('')
        expect(stderr).to include('The bot name example! is invalid.')
      end

      it 'errors if the directory exists' do
        stub_bot_info_error

        working_directory = Dir.mktmpdir
        bot_directory = create_bot_directory(working_directory)

        stderr, stdout = execute_in_directory('bots:generate --bot example', working_directory)

        expect(stdout).to eq('')
        expect(stderr).to eq <<-STDERR
 !    There's already a directory named example. Move it, delete it, change directory, or try another name.
STDERR
      end

      it 'errors if the language is unsupported' do
        stub_bot_info_error

        stderr, stdout = execute('bots:generate --bot example --language go')

        expect(stdout).to eq('')
        expect(stderr).to eq <<-STDOUT
 !    The language go is unsupported.
STDOUT
      end
    end

    describe 'bots:register' do
      it 'registers the bot' do
        stub_bot_info_error
        stub_request(:post, 'http://turbot.opencorporates.com/api/bots').to_return(:status => 200, :body => '{}')

        bot_directory = create_bot_directory
        create_manifest_file(bot_directory)

        stderr, stdout = execute_in_directory('bots:register', bot_directory)

        expect(stderr).to eq('')
        expect(stdout).to eq <<-STDOUT
Registered example!
STDOUT
      end

      it 'errors if no local bot is found' do
        stub_bot_info_error

        stderr, stdout = execute('bots:register')

        expect(stdout).to eq('')
        expect(stderr).to eq <<-STDERR
 !    No bot specified.
 !    Run this command from a bot directory containing a `manifest.json` file, or specify the bot with --bot BOT.
STDERR
      end

      it 'errors if the bot exists in Turbot' do
        stub_bot_info

        bot_directory = create_bot_directory
        create_manifest_file(bot_directory)

        stderr, stdout = execute_in_directory('bots:register', bot_directory)

        expect(stdout).to eq('')
        expect(stderr).to eq <<-STDERR
 !    There's already a bot named example in Turbot. Try another name.
STDERR
      end
    end

    describe 'bots:push' do
      it 'pushes to Turbot' do
        allow(STDIN).to receive(:gets).and_return('y')
        stub_request(:put, 'http://turbot.opencorporates.com/api/bots/example/code').to_return(:status => 200, :body => '{}')

        bot_directory = create_bot_directory
        create_manifest_file(bot_directory)
        create_scraper_file(bot_directory)

        stderr, stdout = execute_in_directory('bots:push', bot_directory)

        expect(stderr).to eq('')
        expect(stdout).to eq <<-STDOUT
This will submit your bot and its data for review.
Are you happy your bot produces valid data (e.g. with `turbot bots:validate`)? [Y/n]
Your bot has been pushed to Turbot and will be reviewed for inclusion as soon as we can. THANK YOU!
STDOUT
      end

      it 'skips confirmation' do
        allow(STDIN).to receive(:gets).and_return('y')
        stub_request(:put, 'http://turbot.opencorporates.com/api/bots/example/code').to_return(:status => 200, :body => '{}')

        bot_directory = create_bot_directory
        create_manifest_file(bot_directory)
        create_scraper_file(bot_directory)

        stderr, stdout = execute_in_directory('bots:push --yes', bot_directory)

        expect(stderr).to eq('')
        expect(stdout).to eq <<-STDOUT
Your bot has been pushed to Turbot and will be reviewed for inclusion as soon as we can. THANK YOU!
STDOUT
      end

      it 'errors if no local bot is found' do
        stderr, stdout = execute('bots:push')

        expect(stdout).to eq('')
        expect(stderr).to eq <<-STDERR
 !    No bot specified.
 !    Run this command from a bot directory containing a `manifest.json` file, or specify the bot with --bot BOT.
STDERR
      end

      it 'aborts if push not confirmed' do
        allow(STDIN).to receive(:gets).and_return('n')

        bot_directory = create_bot_directory
        create_manifest_file(bot_directory)

        stderr, stdout = execute_in_directory('bots:push', bot_directory)

        expect(stdout).to eq <<-STDOUT
This will submit your bot and its data for review.
Are you happy your bot produces valid data (e.g. with `turbot bots:validate`)? [Y/n]
STDOUT
        expect(stderr).to eq <<-STDERR
 !    Aborted.
STDERR
      end
    end

    describe 'bots:validate' do
      before do
        set_turbot_runner_schemas
      end

      it 'validates valid records' do
        bot_directory = create_bot_directory
        create_manifest_file(bot_directory)
        create_scraper_file(bot_directory)

        stderr, stdout = execute_in_directory('bots:validate', bot_directory)

        expect(stderr).to eq('')
        expect(stdout).to eq <<-STDOUT
Validated 1 records!
STDOUT
      end

      it 'reports invalid records' do
        bot_directory = create_bot_directory
        create_manifest_file(bot_directory)
        create_scraper_file(bot_directory, [{'name' => 1}])

        stderr, stdout = execute_in_directory('bots:validate', bot_directory)

        expect(stderr).to eq('')
        expect(stdout).to eq <<-STDOUT

The following record is invalid:
{"name":1}
 * Property of wrong type: name (must be of type string)

Validated 0 records before bot failed!
STDOUT
       end

      it 'reports invalid JSON' do
        bot_directory = create_bot_directory
        create_manifest_file(bot_directory)
        create_scraper_file(bot_directory, ['{'])

        stderr, stdout = execute_in_directory('bots:validate', bot_directory)

        expect(stderr).to eq('')
        expect(stdout).to equal_lines <<-STDOUT

The following line was not valid JSON:
"{"
Validated 0 records before bot failed!
STDOUT
       end

      it 'reports records without identifying fields' do
        bot_directory = create_bot_directory
        create_manifest_file(bot_directory)
        create_scraper_file(bot_directory, [{}])

        stderr, stdout = execute_in_directory('bots:validate', bot_directory)

        expect(stderr).to eq('')
        expect(stdout).to eq <<-STDOUT

The following record is invalid:
{}
 * There were no values provided for any of the identifying fields: name

Validated 0 records before bot failed!
STDOUT
       end

      it 'errors if no local bot is found' do
        stderr, stdout = execute('bots:validate')

        expect(stdout).to eq('')
        expect(stderr).to eq <<-STDERR
 !    No bot specified.
 !    Run this command from a bot directory containing a `manifest.json` file, or specify the bot with --bot BOT.
STDERR
      end

      it 'errors if manifest is invalid JSON' do
        bot_directory = create_bot_directory
        create_manifest_file(bot_directory, '{')

        stderr, stdout = execute_in_directory('bots:validate', bot_directory)

        expect(stdout).to eq('')
        expect(stderr).to eq <<-STDERR
 !    `manifest.json` is invalid JSON. Consider validating it at http://pro.jsonlint.com/
STDERR
      end

      it 'warns if deprecated fields are used' do
        bot_directory = create_bot_directory
        create_scraper_file(bot_directory)
        create_manifest_file(bot_directory, JSON.dump(valid_manifest.merge({
          'allow_duplicates' => true,
          'author' => 'John Q. Public',
          'incremental' => true,
          'public_repository' => 'http://example.com/',
        })))

        stderr, stdout = execute_in_directory('bots:validate', bot_directory)

        expect(stderr).to eq('')
        expect(stdout).to eq <<-STDOUT
WARNING: "allow_duplicates" is deprecated. Use "duplicates_allowed" instead.
WARNING: "author" is deprecated. Use "publisher" instead.
WARNING: "incremental" is deprecated. Use "manually_end_run" instead.
WARNING: "public_repository" is deprecated. Use "public_repo_url" instead.
Validated 1 records!
STDOUT
      end

      it 'errors if manifest is invalid' do
        bot_directory = create_bot_directory
        create_scraper_file(bot_directory)
        create_manifest_file(bot_directory, JSON.dump(valid_manifest.merge({
          'bot_id' => 'example!',
          'title' => 1,
        })))

        stderr, stdout = execute_in_directory('bots:validate', bot_directory)

        expect(stdout).to eq('')
        expect(stderr).to eq <<-STDERR
 !    `manifest.json` is invalid. Please correct the errors:
 !    * The property '#/bot_id' value "example!" did not match the regex '^[A-Za-z0-9._-]+$'
 !    * The property '#/title' of type Fixnum did not match the following type: string
STDERR
      end

      it 'errors if transformer files not in files list' do
        bot_directory = create_bot_directory
        create_scraper_file(bot_directory)
        create_manifest_file(bot_directory, JSON.dump(valid_manifest.merge({
          'transformers' => [{
            'data_type' => 'dummy',
            'file' => 'transformer.rb',
            'identifying_fields' => ['name'],
          }]
        })))

        stderr, stdout = execute_in_directory('bots:validate', bot_directory)

        expect(stdout).to eq('')
        expect(stderr).to eq <<-STDERR
 !    `manifest.json` is invalid. Please correct the errors:
 !    * Some transformer files are not listed in the top-level files: transformer.rb
STDERR
      end

      it 'errors if data_type is invalid' do
        bot_directory = create_bot_directory
        create_scraper_file(bot_directory)
        create_manifest_file(bot_directory, JSON.dump(valid_manifest.merge({
          'data_type' => 'invalid',
        })))

        stderr, stdout = execute_in_directory('bots:validate', bot_directory)

        expect(stdout).to eq('')
        expect(stderr).to eq <<-STDERR
 !    `manifest.json` is invalid. Please correct the errors:
 !    * The property '#/data_type' value "invalid" is not a supported data type.
STDERR
      end
    end

    describe 'bots:preview' do
      it 'submits records' do
        stub_preview

        set_turbot_runner_schemas

        bot_directory = create_bot_directory
        create_manifest_file(bot_directory)
        create_scraper_file(bot_directory)

        allow_any_instance_of(Turbot::Command::Base).to receive(:working_directory).and_return(bot_directory)
        stderr, stdout = execute('bots:preview')
        restore_working_directory_method

        expect(stderr).to eq('')
        expect(stdout).to eq <<-STDOUT
Sending to Turbot...
Submitted 1 records to Turbot.
View your records at http://example.com/
STDOUT
      end

      it 'errors if no local bot is found' do
        stderr, stdout = execute('bots:preview')

        expect(stdout).to eq('')
        expect(stderr).to eq <<-STDERR
 !    No bot specified.
 !    Run this command from a bot directory containing a `manifest.json` file, or specify the bot with --bot BOT.
STDERR
      end

      it 'errors if the scraper is broken' do
        stub_preview

        set_turbot_runner_schemas

        bot_directory = create_bot_directory
        create_manifest_file(bot_directory)
        create_broken_scraper_file(bot_directory)

        allow_any_instance_of(Turbot::Command::Base).to receive(:working_directory).and_return(bot_directory)
        stderr, stdout = execute('bots:preview')
        restore_working_directory_method

        expect(stderr).to eq('')
        expect(stdout).to eq <<-STDOUT
Sending to Turbot...
Bot failed!
STDOUT
      end
    end

    describe 'bots:dump' do
      it 'dumps records' do
        set_turbot_runner_schemas

        bot_directory = create_bot_directory
        create_manifest_file(bot_directory)
        create_scraper_file(bot_directory)

        allow_any_instance_of(Turbot::Command::Base).to receive(:working_directory).and_return(bot_directory)
        stderr, stdout = execute('bots:dump')
        restore_working_directory_method

        expect(stderr).to eq('')
        expect(stdout).to eq <<-STDOUT
{"name":"foo"}
Bot ran successfully!
STDOUT
      end

      it 'reports only validation errors' do
        set_turbot_runner_schemas

        bot_directory = create_bot_directory
        create_manifest_file(bot_directory)
        create_scraper_file(bot_directory, [{'name' => 'foo'}, {'name' => 1}])

        allow_any_instance_of(Turbot::Command::Base).to receive(:working_directory).and_return(bot_directory)
        stderr, stdout = execute('bots:dump --quiet')
        restore_working_directory_method

        expect(stderr).to eq('')
        expect(stdout).to eq <<-STDOUT

The following record is invalid:
{"name":1}
 * Property of wrong type: name (must be of type string)

Bot failed!
STDOUT
      end

      it 'errors if no local bot is found' do
        stderr, stdout = execute('bots:dump')

        expect(stdout).to eq('')
        expect(stderr).to eq <<-STDERR
 !    No bot specified.
 !    Run this command from a bot directory containing a `manifest.json` file, or specify the bot with --bot BOT.
STDERR
      end

      it 'errors if the scraper is broken' do
        set_turbot_runner_schemas

        bot_directory = create_bot_directory
        create_manifest_file(bot_directory)
        create_broken_scraper_file(bot_directory)

        allow_any_instance_of(Turbot::Command::Base).to receive(:working_directory).and_return(bot_directory)
        stderr, stdout = execute('bots:dump')
        restore_working_directory_method

        expect(stderr).to eq('')
        expect(stdout).to eq <<-STDOUT
Bot failed!
STDOUT
      end
    end

    describe '#create_zip_archive' do
      it 'adds all given files to archive' do
        dirs = ['a', 'b', 'a/p', 'b/p']
        paths = ['a/p/x', 'a/y', 'b/p/x', 'b/y', 'z']
        working_directory = Dir.mktmpdir
        dirs.each { |dir| Dir.mkdir(File.join(working_directory, dir)) }
        paths.each { |path| FileUtils.touch(File.join(working_directory, path)) }

        tempfile = Tempfile.new('test')
        tempfile.close
        archive_path = "#{tempfile.path}.zip"

        allow_any_instance_of(Turbot::Command::Base).to receive(:working_directory).and_return(working_directory)
        Turbot::Command::Bots.new.send(:create_zip_archive, archive_path, ['a', 'b/p/x', 'b/y', 'z'])
        restore_working_directory_method

        Zip::File.open(archive_path) do |zipfile|
          expect(zipfile.map { |entry| entry.to_s }).to match_array(paths + ['a/p/'])
        end
      end
    end
  end
end
