module Causes
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
      include FileMethods
      class << self
        attr_accessor :filetype
      end

      def initialize(*args)
        @arguments = args
      end

      def name
        Causes.underscorize self.class.name.to_s.split('::').last
      end

      def skip?
        false
      end

      def staged
        @staged ||= staged_files(self.class.filetype)
      end

      def run_check
        [:bad, 'No checks defined!']
      end

    protected

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
