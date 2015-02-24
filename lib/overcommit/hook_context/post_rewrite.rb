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
  end
end
