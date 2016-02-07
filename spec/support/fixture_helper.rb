module FixtureHelper
  def fixture(path, chmod = 0600)
    filename = File.expand_path(File.join('..', '..', 'fixtures', path), __FILE__)
    if File.exist?(filename)
      FileUtils.chmod(chmod, filename)
    end
    filename
  end
end
