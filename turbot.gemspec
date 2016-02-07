require File.expand_path('../lib/turbot/version', __FILE__)

Gem::Specification.new do |gem|
  gem.name    = "turbot"
  gem.version = Turbot::VERSION

  gem.author      = "OpenCorporates"
  gem.email       = "bots@opencorporates.com"
  gem.homepage    = "https://github.com/openc/turbot-client"
  gem.summary     = "Client library and CLI to deploy and manage bots on Turbot"
  gem.license     = "MIT"

  gem.files         = `git ls-files`.split("\n")
  gem.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  gem.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  gem.require_paths = ["lib"]

  gem.required_ruby_version = '>=1.9.2'

  gem.add_runtime_dependency("netrc", "~> 0.11")
  gem.add_runtime_dependency("json-schema", "~> 2.6.0")
  gem.add_runtime_dependency("rubyzip", ">= 1.0.0")
  gem.add_runtime_dependency("text", "~> 1.3.1")
  gem.add_runtime_dependency("turbot-api", "0.0.14")
  gem.add_runtime_dependency("turbot-runner", "~> 0.2.7")
  
  gem.add_development_dependency("coveralls")
  gem.add_development_dependency("rake", ">= 0.8.7")
  gem.add_development_dependency("rspec", "~> 3.4.0")
  gem.add_development_dependency("sqlite3")
  # coveralls dependency. 1.7.0 requires Ruby version >= 2.0.
  gem.add_development_dependency("tins", "~> 1.6.0")
  gem.add_development_dependency("webmock")
end
