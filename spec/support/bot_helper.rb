module BotHelper
  def valid_manifest
    {
      'bot_id' => 'example',
      'data_type' => 'dummy',
      'files' => ['scraper.rb'],
      'identifying_fields' => ['name'],
      'language' => 'ruby',
      'publisher' => {},
    }
  end

  # API

  def stub_bot_info(bot = 'example')
    stub_request(:get, "http://turbot.opencorporates.com/api/bots/#{bot}?api_key=apikey01").to_return({
      :status => 200,
      :body => JSON.dump({
        'data' => {
          'bot_id' => 'dummy_bot',
          'created_at' => '2010-01-01T00:00:00.000Z',
          'updated_at' => '2010-01-02T00:00:00.000Z',
          'state' => 'scheduled',
        }
      }),
    })
  end

  def stub_bot_info_error(bot = 'example')
    stub_request(:get, "http://turbot.opencorporates.com/api/bots/#{bot}?api_key=apikey01").to_return({
      :status => 402,
      :body => JSON.dump({
        'error_code' => 'bot-not-found',
        'message' => "No bot registered for bot_id example\nIf you have renamed your bot, ...",
      }),
    })
  end

  # Filesystem

  def create_bot_directory(working_directory = nil)
    bot_directory = File.join(working_directory || Dir.mktmpdir, 'example')
    Dir.mkdir(bot_directory)
    bot_directory
  end

  def create_manifest_file(bot_directory, data = nil)
    data ||= JSON.dump(valid_manifest)

    File.open(File.join(bot_directory, 'manifest.json'), 'w') do |f|
      f.write(data)
    end
  end

  def create_scraper_file(bot_directory, record = {'name' => 'foo'})
    File.open(File.join(bot_directory, 'scraper.rb'), 'w') do |f|
      f.write("require 'json'\n")
      f.write("puts JSON.dump(#{record.inspect})\n")
    end
  end

  def create_bad_scraper_file(bot_directory)
    File.open(File.join(bot_directory, 'scraper.rb'), 'w') do |f|
      f.write("class ThisErrorIsExpected < StandardError; end\n")
      f.write("raise ThisErrorIsExpected\n")
    end
  end

  # TurbotRunner

  def set_turbot_runner_schemas
    TurbotRunner::SCHEMAS_PATH.replace(File.expand_path(File.join('..', '..', 'schemas'), __FILE__))
  end

  # Testing

  def execute_in_directory(command, directory)
    allow_any_instance_of(Turbot::Command::Base).to receive(:working_directory).and_return(directory)
    stderr, stdout = execute(command)
    restore_working_directory_method
    [stderr, stdout]
  end

  def restore_working_directory_method
    allow_any_instance_of(Turbot::Command::Base).to receive(:working_directory).and_return(Dir.pwd)
  end
end
