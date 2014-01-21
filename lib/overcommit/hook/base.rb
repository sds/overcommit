require 'wopen3'

module Overcommit::Hook
  # Functionality common to all hooks.
  class Base
    def initialize(config, hook_runner)
      @config = config.hook_config(self)
      @hook_runner = hook_runner
    end

    # Runs the hook.
    def run
      raise NotImplementedError, 'Hook must define `run`'
    end

    def name
      self.class.name.split('::').last
    end

    def description
      @config['description'] || "Running #{name}"
    end

    def required?
      @config['required']
    end

    def quiet?
      @config['quiet']
    end

    def enabled?
      @config['enabled'] != false
    end

    def requires_modified_files?
      @config['requires_files']
    end

    def skip?
      @config['skip']
    end

    def run?
      enabled? &&
        (!skip? || required?) &&
        !(requires_modified_files? && applicable_files.empty?)
    end

    # Gets a list of staged files that apply to this hook based on its
    # configured `include` and `exclude` lists.
    def applicable_files
      @applicable_files ||= staged_files.select { |file| applicable_file?(file) }
    end

  private

    def staged_files
      @hook_runner.staged_files
    end

    # Returns whether the specified file is applicable to this hook based on the
    # hook's `include` and `exclude` file glob patterns.
    def applicable_file?(file)
      includes = Array(@config['include']).map { |glob| convert_glob_to_absolute(glob) }
      included = includes.empty? ||
                 includes.any? { |glob| File.fnmatch(glob, file) }

      excludes = Array(@config['exclude']).map { |glob| convert_glob_to_absolute(glob) }
      excluded = excludes.any? { |glob| File.fnmatch(glob, file) }

      included && !excluded
    end

    def convert_glob_to_absolute(glob)
      repo_root = Overcommit::Utils.repo_root

      if glob.start_with?('**')
        repo_root + glob # Want ** to match items in the repo root as well
      else
        File.join(repo_root, glob)
      end
    end

    # Returns the set of line numbers corresponding to the lines that were
    # changed in a specified file.
    def modified_lines(staged_file)
      @modified_lines ||= {}
      @modified_lines[staged_file] ||= extract_modified_lines(staged_file)
    end

    DIFF_HUNK_REGEX = /
      ^@@\s
      [^\s]+\s           # Ignore old file range
      \+(\d+)(?:,(\d+))? # Extract range of hunk containing start line and number of lines
      \s@@.*$
    /x

    def extract_modified_lines(staged_file)
      lines = Set.new

      `git diff --no-ext-diff --cached -U0 -- #{staged_file}`.
        scan(DIFF_HUNK_REGEX) do |start_line, lines_added|

        lines_added = (lines_added || 1).to_i # When blank, one line was added
        cur_line    = start_line.to_i

        lines_added.times do
          lines.add cur_line
          cur_line += 1
        end
      end

      lines
    end

    # Returns whether a command can be found given the current environment path.
    def in_path?(cmd)
      exts = ENV['PATHEXT'] ? ENV['PATHEXT'].split(';') : ['']
      ENV['PATH'].split(File::PATH_SEPARATOR).each do |path|
        exts.each do |ext|
          exe = File.join(path, "#{cmd}#{ext}")
          return true if File.executable? exe
        end
      end
      false
    end

    # Wrap external subshell calls. This is necessary in order to allow
    # Overcommit to call other Ruby executables without requiring that they be
    # specified in Overcommit's Gemfile--a nasty consequence of using
    # `bundle exec overcommit` while developing locally.
    def command(command)
      with_environment 'RUBYOPT' => nil do
        Wopen3.system(command)
      end
    end

    # Calls a block of code with a modified set of environment variables,
    # restoring them once the code has executed.
    def with_environment(env, &block)
      old_env = {}
      env.each do |var, value|
        old_env[var] = ENV[var.to_s]
        ENV[var.to_s] = value
      end

      yield
    ensure
      old_env.each { |var, value| ENV[var.to_s] = value }
    end
  end
end
