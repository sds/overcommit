module Overcommit::Hook::PostRewrite
  # Updates ctags index for all source code in the repository.
  class IndexTags < Base
    def run
      # Ignore unless this is a rebase (amends are covered by post-commit hook)
      return :pass unless rebase?

      execute_in_background([Overcommit::Utils.script_path('index-tags')])
      :pass
    end
  end
end
