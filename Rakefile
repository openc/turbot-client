# For Bundler.with_clean_env
require 'bundler/setup'

require 'open-uri'

require 'rss'
require 'turbot'

desc "Make a release"
task :release do
  version = Turbot::VERSION
  rubygems_versions = []
  open('http://rubygems.org/gems/turbot/versions.atom') do |rss|
    feed = RSS::Parser.parse(rss, false)
    rubygems_versions = feed.items.map do |i|
      i.id.content.split("/").last
    end
  end
  if rubygems_versions.include? version
    puts "Latest version already published; quitting"
    exit 0
  else
    begin
      puts "Building gem..."
      system("gem build turbot.gemspec")
      puts "Pushing gem..."
      system("gem push $(ls *gem|tail -1)")
    ensure
      system("rm *gem")
    end
    puts "Writing new version on turbot server"
    system(%Q{ssh turbot1 "echo #{version} > /home/openc/sites/turbot_server/current/public/version.txt"})
    puts "Now chance the build_version in omnibus-turbot-client/turbot-client.rb and build the new targets"
  end
end

require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:spec)

task :default => :spec
