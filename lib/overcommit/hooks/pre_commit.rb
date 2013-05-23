module Overcommit
  class PreCommitHook < GitHook::BaseHook
    def requires_modified_files?
      true
    end
  end

  Utils.register_hook(PreCommitHook)
end
