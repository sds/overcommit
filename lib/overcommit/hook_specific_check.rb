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
        attr_accessor :filetype, :stealth, :required

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
        @staged ||= Utils.modified_files.select do |filename|
          filename.end_with?(".#{self.class.filetype}")
        end
      end

      def run_check
        [:bad, 'No checks defined!']
      end

    private

      def modified_files
        Overcommit::Utils.modified_files
      end

      def in_path?(cmd)
        system("which #{cmd} &> /dev/null")
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

      def self.file_type(type)
        self.filetype = type
      end
    end
  end
end
