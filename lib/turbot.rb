require 'fileutils'
require 'optparse'
require 'set'
require 'shellwords'

require 'netrc'
require 'text/levenshtein'
require 'zip'

require 'turbot/helpers'
require 'turbot/helpers/api_helper'
require 'turbot/helpers/netrc_helper'
require 'turbot/helpers/shell_helper'
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
