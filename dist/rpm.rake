# TODO
# * signing
# * yum repository for updates
# * foreman

file pkg("/yum-#{version}/turbot-#{version}.rpm") => "deb:build" do |t|
  mkchdir(File.dirname(t.name)) do
    deb = pkg("/apt-#{version}/turbot-#{version}.deb")
    sh "alien --keep-version --scripts --generate --to-rpm #{deb}"

    spec = "turbot-#{version}/turbot-#{version}-1.spec"
    spec_contents = File.read(spec)
    File.open(spec, "w") do |f|
      # Add ruby requirement, remove benchmark file with ugly filename
      f.puts spec_contents.sub(/\n\n/m, "\nRequires: ruby\nBuildArch: noarch\n\n").
        sub(/^.+has_key-vs-hash\[key\].+$/, "").
        sub(/^License: .*/, "License: MIT\nURL: http://turbot.com\n").
        sub(/^%description/, "%description\nClient library and CLI to deploy bots on Turbot.")
    end
    sh "sed -i s/ruby1.9.1/ruby/ turbot-#{version}/usr/local/turbot/bin/turbot"

    chdir("turbot-#{version}") do
      sh "rpmbuild --buildroot $PWD -bb turbot-#{version}-1.spec"
    end
  end
end

desc "Build an .rpm package"
task "rpm:build" => pkg("/yum-#{version}/turbot-#{version}.rpm")

desc "Remove build artifacts for .rpm"
task "rpm:clean" do
  clean pkg("turbot-#{version}.rpm")
  FileUtils.rm_rf("pkg/yum-#{version}") if Dir.exists?("pkg/yum-#{version}")
end
