require "turbot/client"
require "turbot/version"
require "turbot_api"
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
