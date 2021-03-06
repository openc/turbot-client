require 'fileutils'
require 'optparse'
require 'set'
require 'shellwords'
require 'socket'

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
  DEBUG_VERSION = "#{Turbot::VERSION} (#{RUBY_PLATFORM}) ruby/#{RUBY_VERSION}"
end
