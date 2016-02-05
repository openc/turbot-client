require 'turbot_api'

require 'turbot/version'

module Turbot
  USER_AGENT = "turbot-gem/#{Turbot::VERSION} (#{RUBY_PLATFORM}) ruby/#{RUBY_VERSION}"

  def self.user_agent
    @@user_agent ||= USER_AGENT
  end
end
