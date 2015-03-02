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

  # use git to list files in main repo
  gem_files = %x{ git ls-files }.split("\n").select do |d|
    d =~ %r{^(License|README|bin/|data/|ext/|lib/|spec/|test/|templates/|schema/)}
  end
  # now add files from the schema submodule; if we add more submodules
  # later, change this not to be hard coded
  submodule_files = %x{git submodule foreach --recursive git ls-files}.split("\n").select do |d|
    d =~ %r{^(schemas/)}
  end.map{|x| "schema/#{x}"}
  gem_files.concat(submodule_files)

  gem.files = gem_files

  gem.required_ruby_version = '>=1.9.2'

  gem.add_dependency "turbotlib",       "~> 0.0.8"
  gem.add_dependency "netrc",       "~> 0.7.7"
  gem.add_dependency "rest-client", "~> 1.6.1"
  gem.add_dependency "launchy",     ">= 0.3.2"
  gem.add_dependency "rubyzip",     ">= 1.0.0"
  gem.add_dependency "activesupport", "4.1.4"
  gem.add_dependency "turbot-api", "0.0.14"
  gem.add_dependency "turbot-runner", "0.1.36"
  gem.add_dependency "excon"
end
