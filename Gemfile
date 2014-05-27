source "https://rubygems.org"

gemspec

# XXX move to gemspec when not path-based
gem 'turbot-api', :git => 'git@github.com:openc/turbot-api.git'
gem "rubyzip", "> 1.0.0"

group :development, :test do
  gem "rake",  ">= 0.8.7"
  gem "rr",    "~> 1.0.2"
  gem "excon"
end

group :development do
  gem "aws-s3"
  gem "fpm"
  gem "debugger"
end

group :test do
  gem "fakefs"
  gem "jruby-openssl", :platform => :jruby
  gem "json"
  gem "rspec", ">= 2.0"
  gem "sqlite3"
  gem "webmock"
end
