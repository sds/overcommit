require 'pathname'
require 'overcommit/os'
require 'overcommit/subprocess'
require 'overcommit/command_splitter'
require 'tempfile'

module Overcommit
  # Utility functions for general use.
  module Utils
    # Helper class for doing quick constraint validations on version numbers.
    #
    # This allows us to execute code based on the git version.
    class Version < Gem::Version
      # Overload comparison operators so we can conveniently compare this
      # version directly to a string in code.
      %w[< <= > >= == !=].each do |operator|
        define_method operator do |version|
          case version
          when String
            super(Gem::Version.new(version))
          else
            super(version)
          end
        end
      end
    end

    class << self
      # @return [Overcommit::Logger] logger with which to send debug output
      attr_accessor :log

      def script_path(script)
        File.join(Overcommit::HOME, 'libexec', script)
      end

      # Returns an absolute path to the root of the repository.
      #
      # We do this ourselves rather than call `git rev-parse --show-toplevel` to
      # solve an issue where the .git directory might not actually be valid in
      # tests.
      #
      # @return [String]
      def repo_root
        @repo_root ||=
          begin
            result = execute(%w[git rev-parse --show-toplevel])
            unless result.success?
              raise Overcommit::Exceptions::InvalidGitRepo,
                    'Unable to determine location of GIT_DIR. ' \
                    'Not a recognizable Git repository!'
            end
            result.stdout.chomp("\n")
          end
      end

      # Returns an absolute path to the .git directory for a repo.
      #
      # @return [String]
      def git_dir
        @git_dir ||=
          begin
            result = execute(%w[git rev-parse --git-common-dir])
            unless result.success?
              raise Overcommit::Exceptions::InvalidGitRepo,
                    'Unable to determine location of GIT_DIR. ' \
                    'Not a recognizable Git repository!'
            end
            File.expand_path(result.stdout.chomp("\n"), Dir.pwd)
          end
      end

      # Remove ANSI escape sequences from a string.
      #
      # This is useful for stripping colorized output from external tools.
      #
      # @param text [String]
      # @return [String]
      def strip_color_codes(text)
        text.gsub(/\e\[(\d+)(;\d+)*m/, '')
      end

      # Shamelessly stolen from:
      # stackoverflow.com/questions/1509915/converting-camel-case-to-underscore-case-in-ruby
      def snake_case(str)
        str.gsub(/::/, '/').
            gsub(/([A-Z]+)([A-Z][a-z])/, '\1_\2').
            gsub(/([a-z\d])([A-Z])/, '\1_\2').
            tr('-', '_').
            downcase
      end

      # Converts a string containing underscores/hyphens/spaces into CamelCase.
      def camel_case(str)
        str.split(/_|-| /).map { |part| part.sub(/^\w/, &:upcase) }.join
      end

      # Returns a list of supported hook types (pre-commit, commit-msg, etc.)
      def supported_hook_types
        Dir[File.join(HOOK_DIRECTORY, '*')].
          select { |file| File.directory?(file) }.
          reject { |file| File.basename(file) == 'shared' }.
          map { |file| File.basename(file).tr('_', '-') }
      end

      # Returns a list of supported hook classes (PreCommit, CommitMsg, etc.)
      def supported_hook_type_classes
        supported_hook_types.map do |file|
          file.split('-').map(&:capitalize).join
        end
      end

      # @param cmd [String]
      # @return [true,false] whether a command can be found given the current
      #   environment path.
      def in_path?(cmd)
        # ENV['PATH'] doesn't include the repo root, but that is a valid
        # location for executables, so we want to add it to the list of places
        # we are checking for the executable.
        paths = [repo_root] + ENV['PATH'].split(File::PATH_SEPARATOR)
        exts  = ENV['PATHEXT'] ? ENV['PATHEXT'].split(';') : ['']
        paths.each do |path|
          exts.each do |ext|
            cmd_with_ext = cmd.upcase.end_with?(ext.upcase) ? cmd : "#{cmd}#{ext}"
            full_path = File.join(path, cmd_with_ext)
            return true if File.executable?(full_path)
          end
        end
        false
      end

      # Return the parent command that triggered this hook run
      def parent_command
        if OS.windows?
          `wmic process where ProcessId=#{Process.ppid} get CommandLine /FORMAT:VALUE`.
            strip.
            slice(/(?<=CommandLine=).+/)
        elsif OS.cygwin?
          # Cygwin's `ps` command behaves differently than the traditional
          # Linux version, but a comparable `procps` is provided to compensate.
          `procps -ocommand= -p #{Process.ppid}`.chomp
        else
          `ps -ocommand= -p #{Process.ppid}`.chomp
        end
      end

      # Execute a command in a subprocess, capturing exit status and output from
      # both standard and error streams.
      #
      # This is intended to provide a centralized place to perform any checks or
      # filtering of the command before executing it.
      #
      # The `args` option provides a convenient way of splitting up long
      # argument lists which would otherwise exceed the maximum command line
      # length of the OS. It will break up the list into chunks and run the
      # command with the same prefix `initial_args`, finally combining the
      # output together at the end.
      #
      # This requires that the external command you are running can have its
      # work split up in this way and still produce the same resultant output
      # when outputs of the individual commands are concatenated back together.
      #
      # @param initial_args [Array<String>]
      # @param options [Hash]
      # @option options [Array<String>] :args long list of arguments to split up
      # @return [Overcommit::Subprocess::Result] status, stdout, and stderr
      def execute(initial_args, options = {})
        if initial_args.include?('|')
          raise Overcommit::Exceptions::InvalidCommandArgs,
                'Cannot pipe commands with the `execute` helper'
        end

        result =
          if (splittable_args = options.fetch(:args, [])).any?
            debug(initial_args.join(' ') + " ... (#{splittable_args.length} splittable args)")
            Overcommit::CommandSplitter.execute(initial_args, options)
          else
            debug(initial_args.join(' '))
            Overcommit::Subprocess.spawn(initial_args, options)
          end

        debug("EXIT STATUS: #{result.status}")
        debug("STDOUT: #{result.stdout.inspect}")
        debug("STDERR: #{result.stderr.inspect}")

        result
      end

      # Execute a command in a subprocess, returning immediately.
      #
      # This provides a convenient way to execute long-running processes for
      # which we do not need to know the result.
      #
      # @param args [Array<String>]
      # @return [ChildProcess] detached process spawned in the background
      def execute_in_background(args)
        if args.include?('|')
          raise Overcommit::Exceptions::InvalidCommandArgs,
                'Cannot pipe commands with the `execute_in_background` helper'
        end

        debug("Spawning background task: #{args.join(' ')}")
        Subprocess.spawn_detached(args)
      end

      # Return the number of processors used by the OS for process scheduling.
      #
      # @see https://github.com/grosser/parallel/blob/v1.6.1/lib/parallel/processor_count.rb#L17-L51
      def processor_count # rubocop:disable all
        @processor_count ||=
          begin
            if Overcommit::OS.windows?
              require 'win32ole'
              result = WIN32OLE.connect('winmgmts://').ExecQuery(
                'select NumberOfLogicalProcessors from Win32_Processor'
              )
              result.to_enum.collect(&:NumberOfLogicalProcessors).reduce(:+)
            elsif File.readable?('/proc/cpuinfo')
              IO.read('/proc/cpuinfo').scan(/^processor/).size
            elsif File.executable?('/usr/bin/hwprefs')
              IO.popen('/usr/bin/hwprefs thread_count').read.to_i
            elsif File.executable?('/usr/sbin/psrinfo')
              IO.popen('/usr/sbin/psrinfo').read.scan(/^.*on-*line/).size
            elsif File.executable?('/usr/sbin/ioscan')
              IO.popen('/usr/sbin/ioscan -kC processor') do |out|
                out.read.scan(/^.*processor/).size
              end
            elsif File.executable?('/usr/sbin/pmcycles')
              IO.popen('/usr/sbin/pmcycles -m').read.count("\n")
            elsif File.executable?('/usr/sbin/lsdev')
              IO.popen('/usr/sbin/lsdev -Cc processor -S 1').read.count("\n")
            elsif File.executable?('/usr/sbin/sysctl')
              IO.popen('/usr/sbin/sysctl -n hw.ncpu').read.to_i
            elsif File.executable?('/sbin/sysctl')
              IO.popen('/sbin/sysctl -n hw.ncpu').read.to_i
            else
              # Unknown platform; assume 1 processor
              1
            end
          end
      end

      # Calls a block of code with a modified set of environment variables,
      # restoring them once the code has executed.
      def with_environment(env)
        old_env = {}
        env.each do |var, value|
          old_env[var] = ENV[var.to_s]
          ENV[var.to_s] = value
        end

        yield
      ensure
        old_env.each { |var, value| ENV[var.to_s] = value }
      end

      # Returns whether a file is a broken symlink.
      #
      # @return [true,false]
      def broken_symlink?(file)
        # JRuby's implementation of File.exist? returns true for broken
        # symlinks, so we need use File.size?
        Overcommit::Utils::FileUtils.symlink?(file) && File.size?(file).nil?
      end

      # Convert a glob pattern to an absolute path glob pattern rooted from the
      # repository root directory.
      #
      # @param glob [String]
      # @return [String]
      def convert_glob_to_absolute(glob)
        File.join(repo_root, glob)
      end

      # Return whether a pattern matches the given path.
      #
      # @param pattern [String]
      # @param path [String]
      def matches_path?(pattern, path)
        File.fnmatch?(
          pattern, path,
          File::FNM_PATHNAME | # Wildcard doesn't match separator
          File::FNM_DOTMATCH   # Wildcards match dotfiles
        )
      end

      private

      # Log debug output.
      #
      # This is necessary since some specs indirectly call utility functions but
      # don't explicitly set the logger for the Utils class, so we do a quick
      # check here to see if it's set before we attempt to log.
      #
      # @param args [Array<String>]
      def debug(*args)
        log.debug(*args) if log
      end
    end
  end
end
