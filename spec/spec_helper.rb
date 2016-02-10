require 'rubygems'

unless RUBY_PLATFORM =~ /mswin32|mingw32/
  require 'simplecov'
  require 'coveralls'
  SimpleCov.formatter = Coveralls::SimpleCov::Formatter
  SimpleCov.start do
    add_filter 'spec'
  end
end

require 'rspec'
require 'webmock/rspec'

include WebMock::API

Dir['./spec/support/**/*.rb'].sort.each { |f| require f}
require File.dirname(__FILE__) + '/../lib/turbot'

RSpec.configure do |c|
  c.include(BotHelper)
  c.include(CommandHelper)
  c.include(FixtureHelper)
  c.include(NetrcHelper)
end
