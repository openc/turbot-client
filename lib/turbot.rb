require 'base64'
require 'cgi'
require 'fileutils'
require 'open3'
require 'optparse'
require 'shellwords'

require 'netrc'
require 'zip'

require 'turbot/helpers'
require 'turbot/auth'
require 'turbot/cli'
require 'turbot/command'
require 'turbot/command/base'
require 'turbot/version'

module Turbot
  USER_AGENT = "turbot-gem/#{Turbot::VERSION} (#{RUBY_PLATFORM}) ruby/#{RUBY_VERSION}"

  def self.user_agent
    @@user_agent ||= USER_AGENT
  end
end
