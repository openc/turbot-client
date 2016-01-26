require "spec_helper"
require "turbot/helpers/turbot_postgresql"

include Turbot::Helpers::TurbotPostgresql

describe Turbot::Helpers::TurbotPostgresql::Resolver do

  before do
    @resolver = described_class.new('appname', double(:api))
    allow(@resolver).to receive(:bot_config_vars) { bot_config_vars }
    allow(@resolver).to receive(:bot_attachments) { bot_attachments }
  end

  let(:bot_config_vars) do
    {
      "DATABASE_URL"                => "postgres://default",
      "TURBOT_POSTGRESQL_BLACK_URL" => "postgres://black",
      "TURBOT_POSTGRESQL_IVORY_URL" => "postgres://default"
    }
  end

    let(:bot_attachments) {
      [ Attachment.new({ 'name'  => 'TURBOT_POSTGRESQL_IVORY',
                         'config_var' => 'TURBOT_POSTGRESQL_IVORY_URL',
                         'bot' => {'name' => 'sushi' },
                         'resource' => {'name'  => 'softly-mocking-123',
                                        'value' => 'postgres://default',
                                        'type'  => 'turbot-postgresql:baku' }}),
        Attachment.new({ 'name'  => 'TURBOT_POSTGRESQL_BLACK',
                         'config_var' => 'TURBOT_POSTGRESQL_BLACK_URL',
                         'bot' => {'name' => 'sushi' },
                         'resource' => {'name'  => 'quickly-yelling-2421',
                                        'value' => 'postgres://black',
                                        'type'  => 'turbot-postgresql:zilla' }})
      ]
    }

  context "when the DATABASE_URL has query options" do
    let(:bot_config_vars) do
      {
        "DATABASE_URL"                => "postgres://default?pool=15",
        "TURBOT_POSTGRESQL_BLACK_URL" => "postgres://black",
        "TURBOT_POSTGRESQL_IVORY_URL" => "postgres://default",
        "SHARED_DATABASE_URL"         => "postgres://shared"
      }
    end

    it "resolves DATABASE" do
      att = @resolver.resolve('DATABASE')
      expect(att.display_name).to eq("TURBOT_POSTGRESQL_IVORY_URL (DATABASE_URL)")
      expect(att.url).to eq("postgres://default")
    end
  end

  context "when no bot is specified or inferred, and identifier does not have bot::db shorthand" do
    it 'exits, complaining about the missing bot' do
      api = double('api')
      allow(api).to receive(:get_attachments).and_raise("getting this far will cause an inaccurate 'internal server error' message")

      no_bot_resolver = described_class.new(nil, api)
      expect(no_bot_resolver).to receive(:error){ |msg| expect(msg).to match(/No bot specified/) }.and_raise(SystemExit)
      expect { no_bot_resolver.resolve('black') }.to raise_error(SystemExit)
    end
  end

  context "when the identifier has ::" do
    it 'changes the resolver bot to the left of the ::' do
      expect(@resolver.bot_name).to eq('appname')
      att = @resolver.resolve('app2::black')
      expect(@resolver.bot_name).to eq('app2')
    end

    it 'resolves database names on the right of the ::' do
      att = @resolver.resolve('app2::black')
      expect(att.url).to eq("postgres://black") # since we're mocking out the bot_config_vars
    end

    it 'looks allows nothing after the :: to use the default' do
      att = @resolver.resolve('app2::', 'DATABASE_URL')
      expect(att.url).to eq("postgres://default")
    end
  end

  context "when the DATABASE_URL has no query options" do
    let(:bot_config_vars) do
      {
        "DATABASE_URL"                => "postgres://default",
        "TURBOT_POSTGRESQL_BLACK_URL" => "postgres://black",
        "TURBOT_POSTGRESQL_IVORY_URL" => "postgres://default",
        "SHARED_DATABASE_URL"         => "postgres://shared"
      }
    end

    it "resolves DATABASE" do
      att = @resolver.resolve('DATABASE')
      expect(att.display_name).to eq("TURBOT_POSTGRESQL_IVORY_URL (DATABASE_URL)")
      expect(att.url).to eq("postgres://default")
    end
  end

  it "resolves default using NAME" do
    att = @resolver.resolve('IVORY')
    expect(att.display_name).to eq("TURBOT_POSTGRESQL_IVORY_URL (DATABASE_URL)")
    expect(att.url).to eq("postgres://default")
  end

  it "resolves non-default using NAME" do
    att = @resolver.resolve('BLACK')
    expect(att.display_name).to eq("TURBOT_POSTGRESQL_BLACK_URL")
    expect(att.url).to eq("postgres://black")
  end

  it "resolves default using NAME_URL" do
    att = @resolver.resolve('IVORY_URL')
    expect(att.display_name).to eq("TURBOT_POSTGRESQL_IVORY_URL (DATABASE_URL)")
    expect(att.url).to eq("postgres://default")
  end

  it "resolves non-default using NAME_URL" do
    att = @resolver.resolve('BLACK_URL')
    expect(att.display_name).to eq("TURBOT_POSTGRESQL_BLACK_URL")
    expect(att.url).to eq("postgres://black")
  end

  it "resolves default using lowercase" do
    att = @resolver.resolve('ivory')
    expect(att.display_name).to eq("TURBOT_POSTGRESQL_IVORY_URL (DATABASE_URL)")
    expect(att.url).to eq("postgres://default")
  end

  it "resolves non-default using lowercase" do
    att = @resolver.resolve('black')
    expect(att.display_name).to eq("TURBOT_POSTGRESQL_BLACK_URL")
    expect(att.url).to eq("postgres://black")
  end

  it "resolves non-default using part of name" do
    att = @resolver.resolve('bla')
    expect(att.display_name).to eq("TURBOT_POSTGRESQL_BLACK_URL")
    expect(att.url).to eq("postgres://black")
  end

  it "throws an error if it doesnt exist" do
    expect(@resolver).to receive(:error).with("Unknown database: violet. Valid options are: DATABASE_URL, TURBOT_POSTGRESQL_BLACK_URL, TURBOT_POSTGRESQL_IVORY_URL")
    @resolver.resolve("violet")
  end

  context "default" do

    it "errors if there is no default" do
      expect(@resolver).to receive(:error).with("Unknown database. Valid options are: DATABASE_URL, TURBOT_POSTGRESQL_BLACK_URL, TURBOT_POSTGRESQL_IVORY_URL")
      @resolver.resolve(nil)
    end

    it "uses the default if nothing(nil) specified" do
      att = @resolver.resolve(nil, "DATABASE_URL")
      expect(att.display_name).to eq("TURBOT_POSTGRESQL_IVORY_URL (DATABASE_URL)")
      expect(att.url).to eq("postgres://default")
    end

    it "uses the default if nothing(empty) specified" do
      att = @resolver.resolve('', "DATABASE_URL")
      expect(att.display_name).to eq("TURBOT_POSTGRESQL_IVORY_URL (DATABASE_URL)")
      expect(att.url).to eq("postgres://default")
    end

    it 'throws an error if given an empty string and asked for the default and there is no default' do
      bot_config_vars.delete 'DATABASE_URL'
      expect(@resolver).to receive(:error).with("Unknown database. Valid options are: TURBOT_POSTGRESQL_BLACK_URL, TURBOT_POSTGRESQL_IVORY_URL")
      att = @resolver.resolve('', "DATABASE_URL")
    end

    it 'throws an error if given an empty string and asked for the default and the default doesnt match' do
      bot_config_vars['DATABASE_URL'] = 'something different'
      expect(@resolver).to receive(:error).with("Unknown database. Valid options are: TURBOT_POSTGRESQL_BLACK_URL, TURBOT_POSTGRESQL_IVORY_URL")
      att = @resolver.resolve('', "DATABASE_URL")
    end


  end
end
