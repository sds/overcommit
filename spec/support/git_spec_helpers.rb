# frozen_string_literal: true

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
      create_cmd = %w[git init --initial-branch=master]
      create_cmd += ['--template', options[:template_dir]] if options[:template_dir]
      create_cmd += ['--separate-git-dir', options[:git_dir]] if options[:git_dir]

      result = Overcommit::Utils.execute(create_cmd)
      raise "Unable to create repo: #{result.stderr}" unless result.success?

      # Need to define user info since some CI contexts don't have defaults set
      `git config --local user.name "Overcommit Tester"`
      `git config --local user.email "overcommit@example.com"`
      `git config --local rerere.enabled 0` # Don't record resolutions in tests
      `git config --local commit.gpgsign false`

      yield if block_given?
    end
  end

  # Retrieve sha1 based on git ref
  #
  # @param ref [String] git ref
  # @return [String] ref's sha1
  def get_sha1(ref)
    `git rev-parse #{ref}`.chomp
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
    Array.new(40) { rand(65..90).chr }.join
  end
end
