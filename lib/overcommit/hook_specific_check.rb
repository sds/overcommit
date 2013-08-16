module Overcommit
  module GitHook
    module HookRegistry
      @checks = []
      class << self
        attr_reader :checks

        def included(base)
          @checks << base
        end
      end
    end

    class HookSpecificCheck
      class << self
        attr_accessor :filetypes, :stealth, :required

        def stealth!
          self.stealth = true
        end

        def required!
          self.required = true
        end

        # Can the check be skipped by environment variables? This can always be
        # overriden with `--no-verify`.
        def skippable?
          !required
        end

        def friendly_name
          Overcommit::Utils.underscorize name.to_s.split('::').last
        end
      end

      def initialize(*args)
        @arguments = args
      end

      def name
        self.class.friendly_name
      end

      def skip?
        false
      end

      def stealth?
        self.class.stealth
      end

      def staged
        @staged ||= modified_files.map do |filename|
          filetypes = Array(self.class.filetypes).map { |type| ".#{type}" }
          if filetypes.empty? || filename.end_with?(*filetypes)
            StagedFile.new(filename)
          end
        end.compact
      end

      def run_check
        [:bad, 'No checks defined!']
      end

    private

      def modified_files
        Overcommit::Utils.modified_files
      end

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

      def commit_message_file
        unless @arguments[0] && ::File.exist?(@arguments[0])
          fail 'Not running in the context of a commit message'
        end

        @arguments[0]
      end

      def raw_commit_message
        @raw_commit_message ||= ::IO.readlines(commit_message_file)
      end

      # Strip comments and diff (from git-commit --verbose)
      def commit_message
        @commit_message ||= raw_commit_message.
          reject     { |line| line =~ /^#/ }.
          take_while { |line| !line.start_with?('diff --git') }
      end

      class << self
        def file_type(*types)
          self.filetypes = types
        end
        alias file_types file_type
      end
    end
  end
end
