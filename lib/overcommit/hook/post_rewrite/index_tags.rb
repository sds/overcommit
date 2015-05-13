require 'overcommit/hook/shared/index_tags'

module Overcommit::Hook::PostRewrite
  # Updates ctags index for all source code in the repository.
  #
  # @see {Overcommit::Hook::Shared::IndexTags}
  class IndexTags < Base
    include Overcommit::Hook::Shared::IndexTags

    def run
      # Ignore unless this is a rebase (amends are covered by post-commit hook)
      return :pass unless rebase?

      super
    end
  end
end
