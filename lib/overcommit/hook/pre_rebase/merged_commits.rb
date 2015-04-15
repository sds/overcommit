module Overcommit::Hook::PreRebase
  # Prevents rebasing commits that have already been merged into one of
  # a specified set of branches.
  class MergedCommits < Base
    def run
      # Allow rebasing a detached HEAD since no refs are changed.
      return :pass if detached_head? || illegal_commits.empty?

      message = 'Cannot rebase commits that have already been merged into ' \
                "one of #{branches.join(', ')}"

      [:fail, message]
    end

    private

    def branches
      @branches ||= config['branches']
    end

    def illegal_commits
      @illegal_commits ||= rebased_commits.select do |commit_sha1|
        branches_containing_commit =
          Overcommit::GitRepo.branches_containing_commit(commit_sha1)
        (branches_containing_commit & branches).any?
      end
    end
  end
end
