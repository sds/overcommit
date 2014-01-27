module Overcommit::HookContext
  class CommitMsg < Base
    # User commit message stripped of comments and diff (from verbose output).
    def commit_message
      raw_commit_message.
        reject     { |line| line =~ /^#/ }.
        take_while { |line| !line.start_with?('diff --git') }
    end

    def commit_message_file
      @args[0]
    end

  private

    def raw_commit_message
      ::IO.readlines(commit_message_file)
    end
  end
end
