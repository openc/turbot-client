#Manage bots (generate template, validate data, submit code)
#
class Turbot::Command::Bots < Turbot::Command::Base
  BOT_ID_RE = /\A[A-Za-z0-9_-]+\z/.freeze

  def initialize(*args)
    super

    require 'turbot_runner'
    require 'turbot/handlers/base_handler'
    require 'turbot/handlers/dump_handler'
    require 'turbot/handlers/preview_handler'
    require 'turbot/handlers/validation_handler'
  end

  # bots
  #
  #List your bots.
  #
  #Example:
  #
  #  $ turbot bots
  #  example1
  #  example2
  #
  def index
    validate_arguments!

    response = api.list_bots
    if response.is_a?(Turbot::API::SuccessResponse)
      if response.data.empty?
        display 'You have no bots.'
      else
        response.data.each do |bot|
          display bot[:bot_id]
        end
      end
    else
      error_message(response)
    end
  end
  alias_command 'list', 'bots'

  # bots:info [--bot BOT]
  #
  #Show a bot's details.
  #
  #  -b, --bot BOT # a bot ID
  #
  #Example:
  #
  #  $ turbot bots:info --bot example
  #  bot_id: example
  #  created_at: 2010-01-01T00:00:00.000Z
  #  updated_at: 2010-01-02T00:00:00.000Z
  #  state: scheduled
  #
  def info
    validate_arguments!
    error_if_no_local_bot_found

    response = api.show_bot(bot)
    if response.is_a?(Turbot::API::SuccessResponse)
      response.data.each do |key,value|
        display "#{key}: #{value}"
      end
    else
      error_message(response)
    end
  end
  alias_command 'info', 'bots:info'

  # bots:generate --bot BOT
  #
  #Generate a bot template in the specified language.
  #
  #  -b, --bot BOT # a bot ID
  #  -l, --language LANGUAGE # ruby (default) or python
  #
  #Example:
  #
  #  $ turbot bots:generate --bot my_amazing_bot --language ruby
  #  Created new bot template for my_amazing_bot!
  #
  def generate
    validate_arguments!
    error_if_bot_exists_in_turbot

    # Check the bot name.
    unless bot[BOT_ID_RE]
      error "The bot name #{bot} is invalid. Bot names must contain only lowercase letters (a-z), numbers (0-9), underscore (_) or hyphen (-)."
    end

    # Check collision with existing directory.
    bot_directory = File.join(working_directory, bot)
    if File.exists?(bot_directory)
      error "There's already a directory named #{bot}. Move it, delete it, change directory, or try another name."
    end

    language = (options[:language] || 'ruby').downcase
    scraper_template = File.expand_path("../../../../data/templates/#{language}", __FILE__)

    # Check language.
    unless File.exists?(scraper_template)
      error "The language #{language} is unsupported."
    end

    scraper_name = case language
    when 'ruby'
      'scraper.rb'
    when 'python'
      'scraper.py'
    end

    # Create the scraper.
    FileUtils.mkdir(bot_directory)
    FileUtils.cp(File.join(scraper_template, scraper_name), File.join(bot_directory, scraper_name))

    # Create the license.
    license_template = File.expand_path('../../../../data/templates/LICENSE.txt', __FILE__)
    FileUtils.cp(license_template, File.join(bot_directory, 'LICENSE.txt'))

    # Create the manifest.
    manifest_template = File.expand_path('../../../../data/templates/manifest.json', __FILE__)
    manifest = File.read(manifest_template).
      sub('{{bot_id}}', bot).
      sub('{{scraper_name}}', scraper_name).
      sub('{{language}}', language)
    File.open(File.join(bot_directory, 'manifest.json'), 'w') do |f|
      f.write(JSON.pretty_generate(JSON.load(manifest)))
    end

    display "Created new bot template for #{bot}!"
  end

  # bots:register
  #
  #Register a bot with Turbot. Must be run from a bot directory containing a `manifest.json` file.
  #
  #Example:
  #
  #  $ turbot bots:register
  #  Registered my_amazing_bot!
  #
  def register
    validate_arguments!
    error_if_no_local_bot_found
    error_if_bot_exists_in_turbot

    response = api.create_bot(bot, parse_manifest)
    if response.is_a?(Turbot::API::SuccessResponse)
      display "Registered #{bot}!"
    else
      error_message(response)
    end
  end

  # bots:push
  #
  #Push the bot's code to Turbot. Must be run from a bot directory containing a `manifest.json` file.
  #
  #  -y, --yes # skip confirmation
  #
  #Example:
  #
  #  $ turbot bots:push
  #  This will submit your bot and its data for review.
  #  Are you happy your bot produces valid data (e.g. with `turbot bots:validate`)? [Y/n]
  #  Your bot has been pushed to Turbot and will be reviewed for inclusion as soon as we can. THANK YOU!
  #
  def push
    validate_arguments!
    error_if_no_local_bot_found

    unless options[:yes]
      display 'This will submit your bot and its data for review.'
      display 'Are you happy your bot produces valid data (e.g. with `turbot bots:validate`)? [Y/n]'
      answer = ask
      unless ['', 'y'].include?(answer.downcase.strip)
        error 'Aborted.'
      end
    end

    # TODO Validate the manifest.json file.

    manifest = parse_manifest
    archive_path = "#{Tempfile.new(bot).path}.zip"
    create_zip_archive(archive_path, manifest['files'] + ['manifest.json'])

    response = File.open(archive_path) do |f|
      api.update_code(bot, f)
    end
    if response.is_a?(Turbot::API::SuccessResponse)
      display 'Your bot has been pushed to Turbot and will be reviewed for inclusion as soon as we can. THANK YOU!'
    else
      error_message(response)
    end
  end
  alias_command 'push', 'bots:push'


  # bots:validate
  #
  #Validate the `manifest.json` file and validate the bot's output against its schema.
  #
  #Example:
  #
  #  $ turbot bots:validate
  #  Validated 2 records!
  #
  def validate
    validate_arguments!
    error_if_no_local_bot_found

    manifest = parse_manifest

    { 'allow_duplicates' => 'duplicates_allowed',
      'author' => 'publisher',
      'incremental' => 'manually_end_run',
      'public_repository' => 'public_repo_url',
    }.each do |deprecated,field|
      if manifest[deprecated]
        display %(WARNING: "#{deprecated}" is deprecated. Use "#{field}" instead.)
      end
    end

    schema = JSON.load(File.read(File.expand_path('../../../../data/schema.json', __FILE__)))
    validator = JSON::Validator.new(schema, manifest, {
      clear_cache: false,
      parse_data: false,
      record_errors: true,
      errors_as_objects: true,
    })

    errors = validator.validate
    if errors.any?
      messages = ['`manifest.json` is invalid. Please correct the errors:']
      errors.each do |error|
        messages << "* #{error.fetch(:message).sub(/ in schema \S+\z/, '')}"
      end
      error messages.join("\n")
    end

    if manifest['transformers']
      difference = manifest['transformers'].map { |transformer| transformer['file'] } - manifest['files']
      if difference.any?
        messages = ['`manifest.json` is invalid. Please correct the errors:']
        messages << "* Some transformer files are not listed in the top-level files: #{difference.join(', ')}"
        error messages.join("\n")
      end
    end

    handler = Turbot::Handlers::ValidationHandler.new
    runner = TurbotRunner::Runner.new(working_directory, :record_handler => handler)
    begin
      rc = runner.run
    rescue TurbotRunner::InvalidDataType
      messages = ['`manifest.json` is invalid. Please correct the errors:']
      messages << %(* The property '#/data_type' value "#{manifest['data_type']}" is not a supported data type.)
      error messages.join("\n")
    end

    if rc == TurbotRunner::Runner::RC_OK
      display "Validated #{handler.count} records!"
    else
      display "Validated #{handler.count} records before bot failed!"
    end
  end

  # bots:dump
  #
  #Execute the bot locally and write the bot's output to STDOUT.
  #
  #Example:
  #
  #  $ turbot bots:dump
  #  {'foo': 'bar'}
  #  {'foo2': 'bar2'}
  #
  def dump
    validate_arguments!
    error_if_no_local_bot_found

    handler = Turbot::Handlers::DumpHandler.new
    runner = TurbotRunner::Runner.new(working_directory, :record_handler => handler)
    rc = runner.run

    if rc == TurbotRunner::Runner::RC_OK
      display 'Bot ran successfully!'
    else
      display 'Bot failed!'
    end
  end

  # bots:preview
  #
  #Send bot data to Turbot for remote previewing or sharing.
  #
  #Example:
  #
  #  $ turbot bots:preview
  #  Sending to Turbot...
  #  Submitted 2 records to Turbot.
  #  View your records at http://turbot.opencorporates.com/..
  #
  def preview
    validate_arguments!
    error_if_no_local_bot_found

    response = api.update_bot(bot, parse_manifest)
    if response.is_a?(Turbot::API::FailureResponse)
      error_message(response)
    end

    response = api.destroy_draft_data(bot)
    if response.is_a?(Turbot::API::FailureResponse)
      error_message(response)
    end

    display 'Sending to Turbot...'

    handler = Turbot::Handlers::PreviewHandler.new(bot, api)
    runner = TurbotRunner::Runner.new(working_directory, :record_handler => handler)
    rc = runner.run

    if rc == TurbotRunner::Runner::RC_OK
      response = handler.submit_batch
      if response.is_a?(Turbot::API::SuccessResponse)
        if handler.count > 0
          display "Submitted #{handler.count} records to Turbot.\nView your records at #{response.data[:url]}"
        else
          display 'No records sent.'
        end
      else
        error_message(response)
      end
    else
      display 'Bot failed!'
    end
  end

private

  def error_if_no_local_bot_found
    unless bot
      error "No bot specified.\nRun this command from a bot directory containing a `manifest.json` file, or specify the bot with --bot BOT."
    end
  end

  def error_if_bot_exists_in_turbot
    if api.show_bot(bot).is_a?(Turbot::API::SuccessResponse)
      error "There's already a bot named #{bot} in Turbot. Try another name."
    end
  end

  def error_message(response)
    suffix = response.error_code && ": #{response.error_code}"
    error "#{response.message} (HTTP #{response.code}#{suffix})"
  end

  def create_zip_archive(archive_path, basenames)
    Zip.continue_on_exists_proc = true

    Zip::File.open(archive_path, Zip::File::CREATE) do |zipfile|
      basenames.each do |basename|
        filename = File.join(working_directory, basename)

        if File.directory?(filename)
          Dir["#{filename}/**/*"].each do |filename1|
            basename1 = Pathname.new(filename1).relative_path_from(Pathname.new(working_directory))
            zipfile.add(basename1, filename1)
          end
        else
          zipfile.add(basename, filename)
        end
      end
    end
  end
end
