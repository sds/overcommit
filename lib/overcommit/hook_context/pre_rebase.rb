module Overcommit::HookContext
  # Contains helpers related to contextual information used by pre-rebase
  # hooks.
  class PreRebase < Base
    # Returns the name of the branch we are rebasing onto.
    def upstream_branch
      @args[0]
    end

    # Returns the name of the branch being rebased. Empty if rebasing a
    # detached HEAD.
    def rebased_branch
      @rebased_branch ||=
        @args[1] || `git symbolic-ref --short --quiet HEAD`.chomp
    end

    # Returns whether we are rebasing a detached HEAD rather than a branch
    def detached_head?
      rebased_branch.empty?
    end

    # Returns whether this rebase is a fast-forward
    def fast_forward?
      rebased_commits.empty?
    end

    # Returns the SHA1-sums of the series of commits to be rebased
    # in reverse topological order.
    def rebased_commits
      rebased_ref = detached_head? ? 'HEAD' : rebased_branch
      @rebased_commits ||=
        `git rev-list --topo-order --reverse #{upstream_branch}..#{rebased_ref}`.
          split("\n")
    end
  end
end
