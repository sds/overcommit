require 'tmpdir'

# Helpers for creating temporary repositories and directories for testing.
module GitSpecHelpers
  module_function

  # Creates an empty git repository, allowing you to execute a block where
  # the current working directory is set to that repository's root directory.
  #
  # @param options [Hash]
  # @return [String] path of the repository
  def repo(options = {})
    directory('some-repo') do
      `git init --template="#{options[:template_dir]}"`

      # Need to define user info since some CI contexts don't have defaults set
      `git config --local user.name "Overcommit Tester"`
      `git config --local user.email "overcommit@example.com"`
      `git config --local rerere.enabled 0` # Don't record resolutions in tests

      yield if block_given?
    end
  end

  # Creates a directory (with an optional specific name) in a temporary
  # directory which will automatically be destroyed.
  #
  # @param name [String] base name of the directory
  # @return [String] path of the directory that was created
  def directory(name = 'some-dir', &block)
    tmpdir = Dir.mktmpdir.tap do |path|
      Dir.chdir(path) do
        Dir.mkdir(name)
        Dir.chdir(name, &block) if block_given?
      end
    end

    File.join(tmpdir, name)
  end

  # Returns a random git object hash.
  #
  # @return [String]
  def random_hash
    Array.new(40) { (65 + rand(26)).chr }.join
  end
end
