module Overcommit::Hook::PostRewrite
  # Updates ctags index for all source code in the repository.
  class IndexTags < Base
    # Location of the tag indexing script.
    SCRIPT_LOCATION = Overcommit::Utils.script_path('index-tags')

    def run
      # Ignore unless this is a rebase (amends are covered by post-commit hook)
      return :pass unless rebase?

      ctags_args = Array(config['ctags_arguments'])
      execute_in_background([SCRIPT_LOCATION] + ctags_args)

      :pass
    end
  end
end
