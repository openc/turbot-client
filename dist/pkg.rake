require "erb"

file pkg("turbot-#{version}.pkg") => distribution_files("pkg") do |t|
  tempdir do |dir|
    mkchdir("turbot-client") do
      assemble_distribution
      assemble_gems
      assemble resource("pkg/turbot"), "bin/turbot", 0755
    end

    kbytes = %x{ du -ks turbot-client | cut -f 1 }
    num_files = %x{ find turbot-client | wc -l }

    mkdir_p "pkg"
    mkdir_p "pkg/Resources"
    mkdir_p "pkg/turbot-client.pkg"

    dist = File.read(resource("pkg/Distribution.erb"))
    dist = ERB.new(dist).result(binding)
    File.open("pkg/Distribution", "w") { |f| f.puts dist }

    dist = File.read(resource("pkg/PackageInfo.erb"))
    dist = ERB.new(dist).result(binding)
    File.open("pkg/turbot-client.pkg/PackageInfo", "w") { |f| f.puts dist }

    mkdir_p "pkg/turbot-client.pkg/Scripts"
    cp resource("pkg/postinstall"), "pkg/turbot-client.pkg/Scripts/postinstall"
    chmod 0755, "pkg/turbot-client.pkg/Scripts/postinstall"

    sh %{ mkbom -s turbot-client pkg/turbot-client.pkg/Bom }

    Dir.chdir("turbot-client") do
      sh %{ pax -wz -x cpio . > ../pkg/turbot-client.pkg/Payload }
    end

    sh %{ curl http://turbot-toolbelt.s3.amazonaws.com/ruby.pkg -o ruby.pkg }
    sh %{ pkgutil --expand ruby.pkg ruby }
    mv "ruby/ruby-1.9.3-p194.pkg", "pkg/ruby.pkg"

    sh %{ pkgutil --flatten pkg turbot-#{version}.pkg }

    cp_r "turbot-#{version}.pkg", t.name
  end
end

desc "build pkg"
task "pkg:build" => pkg("turbot-#{version}.pkg")

desc "clean pkg"
task "pkg:clean" do
  clean pkg("turbot-#{version}.pkg")
end

task "pkg:release" do
  raise "pkg:release moved to toolbelt repo"
end
