source "https://rubygems.org"

gemspec

gem 'json-schema', :git => 'git://github.com/ruby-json-schema/json-schema.git', :ref => 'aded4d798a48545184dae7ae0a3bb41ec2794c88'

group :development, :test do
  gem "rake",  ">= 0.8.7"
  gem "rr",    "~> 1.0.2"
  gem "excon"
end

group :development do
  gem "aws-s3"
  gem "fpm"
  gem "pry"
end

group :test do
  gem "fakefs"
  gem "jruby-openssl", :platform => :jruby
  gem "json"
  gem "rspec", ">= 2.0"
  gem "sqlite3"
  gem "webmock"
end

