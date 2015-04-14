module Overcommit::Hook::PreRebase
  # Prevents destructive updates to specified branches.
  class MergedCommits < Base
    def run
      # Allow rebasing a detached HEAD since no refs are changed.
      return :pass if detached_head? || illegal_commits.empty?

      message = 'Cannot rebase commits that have already been merged into ' \
                "one of #{dest_branches.join(',')}"

      [:fail, message]
    end

    private

    def dest_branches
      @dest_branches ||= config['dest_branches']
    end

    def illegal_commits
      @illegal_commits ||= rebased_commits.select do |commit_sha1|
        branches_containing_commit =
          Overcommit::GitRepo.branches_containing_commit(commit_sha1)
        (branches_containing_commit & dest_branches).any?
      end
    end
  end
end
