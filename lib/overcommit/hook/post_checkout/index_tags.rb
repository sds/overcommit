require 'overcommit/hook/shared/index_tags'

module Overcommit::Hook::PostCheckout
  # Updates ctags index for all source code in the repository.
  class IndexTags < Base
    include Overcommit::Hook::Shared::IndexTags
  end
end
