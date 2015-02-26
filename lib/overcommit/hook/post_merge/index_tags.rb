module Overcommit::Hook::PostMerge
  # Updates ctags index for all source code in the repository.
  class IndexTags < Base
    def run
      execute_in_background([Overcommit::Utils.script_path('index-tags')])
      :pass
    end
  end
end
