require "turbot/client"
require "turbot/updater"
require "turbot/version"
require "turbot/api"
require "turbot/errors"

module Turbot

  USER_AGENT = "turbot-gem/#{Turbot::VERSION} (#{RUBY_PLATFORM}) ruby/#{RUBY_VERSION}"

  def self.user_agent
    @@user_agent ||= USER_AGENT
  end

  def self.user_agent=(agent)
    @@user_agent = agent
  end

end
