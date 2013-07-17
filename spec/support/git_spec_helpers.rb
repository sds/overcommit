module GitSpecHelpers
  def repo(&block)
    Dir.mktmpdir.tap do |path|
      Dir.chdir(path) { `git init` }
      Dir.chdir(path, &block)
    end
  end

  extend self
end
