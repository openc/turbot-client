module Turbot
  module Distribution
    def self.files
      (Dir[File.expand_path("../../../{Gemfile,turbot.gemspec,.gitmodules,schema}", __FILE__)] + Dir[File.expand_path("../../../{.git,bin,data,lib,templates}/**/*", __FILE__)]).select do |file|
        File.file?(file)
      end
    end
  end
end
