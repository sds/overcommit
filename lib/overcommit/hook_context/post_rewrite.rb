module Overcommit::HookContext
  # Contains helpers for contextual information used by post-rewrite hooks.
  class PostRewrite < Base
    # Returns whether this post-rewrite was triggered by `git commit --amend`.
    #
    # @return [true,false]
    def amend?
      @args[0] == 'amend'
    end

    # Returns whether this post-rewrite was triggered by `git rebase`.
    #
    # @return [true,false]
    def rebase?
      @args[0] == 'rebase'
    end

    # Returns the list of commits rewritten by the action that triggered this
    # hook run.
    #
    # @return [Array<RewrittenCommit>]
    def rewritten_commits
      @rewritten_commits ||= input_lines.map do |line|
        RewrittenCommit.new(*line.split(' '))
      end
    end

    # Struct encapsulating the old and new SHA1 hashes of a rewritten commit
    RewrittenCommit = Struct.new(:old_hash, :new_hash)
  end
end
