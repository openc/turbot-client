file pkg("turbot-#{version}.gem") => distribution_files("gem") do |t|
  sh "gem build turbot.gemspec"
  sh "mv turbot-#{version}.gem #{t.name}"
end

task "gem:build" => pkg("turbot-#{version}.gem")

task "gem:clean" do
  clean pkg("turbot-#{version}.gem")
end

task "gem:release" => "gem:build" do |t|
 sh "gem push #{pkg("turbot-#{version}.gem")}"
 sh "git tag v#{version}"
 sh "git push origin master --tags"
end
