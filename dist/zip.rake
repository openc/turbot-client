require "zip/zip"

file pkg("turbot-#{version}.zip") => distribution_files("zip") do |t|
  tempdir do |dir|
    mkchdir("turbot-client") do
      assemble_distribution
      assemble_gems
      Zip::ZipFile.open(t.name, Zip::ZipFile::CREATE) do |zip|
        Dir["**/*"].each do |file|
          zip.add(file, file) { true }
        end
      end
    end
  end
end

file pkg("turbot-#{version}.zip.sha256") => pkg("turbot-#{version}.zip") do |t|
  File.open(t.name, "w") do |file|
    file.puts Digest::SHA256.file(t.prerequisites.first).hexdigest
  end
end

task "zip:build" => pkg("turbot-#{version}.zip")
task "zip:sign"  => pkg("turbot-#{version}.zip.sha256")

def zip_signature
  File.read(pkg("turbot-#{version}.zip.sha256")).chomp
end

task "zip:clean" do
  clean pkg("turbot-#{version}.zip")
end

task "zip:release" => %w( zip:build zip:sign ) do |t|
  store pkg("turbot-#{version}.zip"), "turbot-client/turbot-client-#{version}.zip"
  store pkg("turbot-#{version}.zip"), "turbot-client/turbot-client-beta.zip" if beta?
  store pkg("turbot-#{version}.zip"), "turbot-client/turbot-client.zip" unless beta?

  sh "turbot config:add UPDATE_HASH=#{zip_signature} -a toolbelt"
end
