# frozen_string_literal: true

module Overcommit::HookContext
  # Contains helpers related to contextual information used by prepare-commit-msg
  # hooks.
  class PrepareCommitMsg < Base
    # Returns the name of the file that contains the commit log message
    def commit_message_filename
      @args[0]
    end

    # Returns the source of the commit message, and can be: message (if a -m or
    # -F option was given); template (if a -t option was given or the
    # configuration option commit.template is set); merge (if the commit is a
    # merge or a .git/MERGE_MSG file exists); squash (if a .git/SQUASH_MSG file
    # exists); or commit, followed by a commit SHA-1 (if a -c, -C or --amend
    # option was given)
    def commit_message_source
      @args[1]&.to_sym
    end

    # Returns the commit's SHA-1.
    # If commit_message_source is :commit, it's passed through the command-line.
    def commit_message_source_ref
      @args[2] || `git rev-parse HEAD`
    end

    # Lock for the pre_commit_message file. Should be shared by all
    # prepare-commit-message hooks
    def lock
      @lock ||= Monitor.new
    end
  end
end
