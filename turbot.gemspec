$:.unshift File.expand_path("../lib", __FILE__)
require "turbot/version"

Gem::Specification.new do |gem|
  gem.name    = "turbot"
  gem.version = Turbot::VERSION

  gem.author      = "Turbot"
  gem.email       = "support@turbot.com"
  gem.homepage    = "http://turbot.com/"
  gem.summary     = "Client library and CLI to deploy apps on Turbot."
  gem.description = "Client library and command-line tool to deploy and manage apps on Turbot."
  gem.executables = "turbot"
  gem.license     = "MIT"
  gem.post_install_message = <<-MESSAGE
 !    The `turbot` gem has been deprecated and replaced with the Turbot Toolbelt.
 !    Download and install from: https://toolbelt.turbot.com
 !    For API access, see: https://github.com/turbot/turbot.rb
  MESSAGE

  gem.files = %x{ git ls-files }.split("\n").select { |d| d =~ %r{^(License|README|bin/|data/|ext/|lib/|spec/|test/|templates/)} }

  gem.required_ruby_verion = '>=1.9.2'

  gem.add_dependency "netrc",       "~> 0.7.7"
  gem.add_dependency "rest-client", "~> 1.6.1"
  gem.add_dependency "launchy",     ">= 0.3.2"
  gem.add_dependency "rubyzip",     ">= 1.0.0"
  gem.add_dependency "json-schema"
  gem.add_dependency "turbot-api"
end
