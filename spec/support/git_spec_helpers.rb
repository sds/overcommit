require 'tmpdir'

# Helpers for creating temporary repositories and directories for testing.
module GitSpecHelpers
  module_function

  def repo(name = 'some-repo', &block)
    directory(name) do
      `git init --template=""` # Ensure no template directory is applied
      `mkdir -p .git/hooks` # Since we don't specify template, need to create ourselves
      block.call if block_given?
    end
  end

  # Creates a directory (with an optional specific name) in a temporary
  # directory which will automatically be destroyed.
  def directory(name = 'some-dir', &block)
    tmpdir = Dir.mktmpdir.tap do |path|
      Dir.chdir(path) do
        Dir.mkdir(name)
        Dir.chdir(name) do
          block.call if block_given?
        end
      end
    end

    File.join(tmpdir, name)
  end

  def random_hash
    40.times.map { (65 + rand(26)).chr }.join
  end
end
