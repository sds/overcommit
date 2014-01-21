module Overcommit::HookRunner
  # Manages loading and running commit-msg hooks.
  class CommitMsg < Base
    # User commit message stripped of comments and diff (from verbose output)
    def commit_message
      @commit_message ||= raw_commit_message.
        reject     { |line| line =~ /^#/ }.
        take_while { |line| !line.start_with?('diff --git') }
    end

    def raw_commit_message
      @raw_commit_message ||= ::IO.readlines(commit_message_file)
    end

  private

    def commit_message_file
      unless @args[0] && ::File.exist?(@args[0])
        fail 'Not running in the context of a commit message'
      end

      @args[0]
    end
  end
end
