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
        attr_accessor :filetype
        attr_accessor :stealth

        def stealth!
          self.stealth = true
        end
      end

      def initialize(*args)
        @arguments = args
      end

      def name
        Overcommit::Utils.underscorize self.class.name.to_s.split('::').last
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

      def in_path?(cmd)
        system("which #{cmd} &> /dev/null")
      end

      def commit_message
        @commit_message ||= begin
          unless @arguments[0] && ::File.exist?(@arguments[0])
            fail 'Not running in the context of a commit message'
          end

          File.readlines(@arguments[0])
        end
      end

      # Strip comments and diff (from git-commit --verbose)
      def user_commit_message
        @user_commit_message ||= commit_message.
          reject     { |line| line =~ /^#/ }.
          take_while { |line| !line.start_with?('diff --git') }
      end

      def self.file_type(type)
        self.filetype = type
      end
    end
  end
end
