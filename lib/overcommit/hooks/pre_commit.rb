module Overcommit
  class PreCommitHook < GitHook::BaseHook
    def requires_modified_files?
      true
    end
  end

  GitHook.register_hook(PreCommitHook)
end
