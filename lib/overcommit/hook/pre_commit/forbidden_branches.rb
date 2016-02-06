module Overcommit::Hook::PreCommit
  # Prevents commits to branches matching one of the configured patterns.
  class ForbiddenBranches < Base
    def run
      return :pass unless forbidden_commit?

      [:fail, "Committing to #{current_branch} is forbidden"]
    end

    private

    def forbidden_commit?
      forbidden_branch_patterns.any? { |p| File.fnmatch(p, current_branch) }
    end

    def forbidden_branch_patterns
      @forbidden_branch_patterns ||= Array(config['branch_patterns'])
    end

    def current_branch
      @current_branch ||= Overcommit::GitRepo.current_branch
    end
  end
end
