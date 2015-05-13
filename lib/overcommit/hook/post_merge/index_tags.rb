require 'overcommit/hook/shared/index_tags'

module Overcommit::Hook::PostMerge
  # Updates ctags index for all source code in the repository.
  #
  # @see {Overcommit::Hook::Shared::IndexTags}
  class IndexTags < Base
    include Overcommit::Hook::Shared::IndexTags
  end
end
