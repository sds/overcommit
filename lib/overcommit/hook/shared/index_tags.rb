module Overcommit::Hook::Shared
  # Shared code used by all IndexTags hooks. It runs ctags in the background so
  # your tag definitions are up-to-date.
  #
  # @see http://ctags.sourceforge.net/
  module IndexTags
    def run
      execute_in_background([Overcommit::Utils.script_path('index-tags')])
      :pass
    end
  end
end
