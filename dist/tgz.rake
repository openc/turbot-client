file pkg("turbot-#{version}.tgz") => distribution_files("tgz") do |t|
  tempdir do |dir|
    mkchdir("turbot-client") do
      assemble_distribution
      assemble_gems
      assemble resource("tgz/turbot"), "bin/turbot", 0755
    end

    sh "chmod -R go+r turbot-client"
    sh "sudo chown -R 0:0 turbot-client"
    sh "tar czf #{t.name} turbot-client"
    sh "sudo chown -R $(whoami) turbot-client"
  end
end

task "tgz:build" => pkg("turbot-#{version}.tgz")

task "tgz:clean" do
  clean pkg("turbot-#{version}.tgz")
end

task "tgz:release" => "tgz:build" do |t|
  store pkg("turbot-#{version}.tgz"), "turbot-client/turbot-client-#{version}.tgz"
  store pkg("turbot-#{version}.tgz"), "turbot-client/turbot-client-beta.tgz" if beta?
  store pkg("turbot-#{version}.tgz"), "turbot-client/turbot-client.tgz" unless beta?
end
