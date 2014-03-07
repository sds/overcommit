module Overcommit::HookContext
  # Contains helpers related to contextual information used by post-checkout
  # hooks.
  class PostCheckout < Base
    # Returns the ref of the HEAD that we transitioned from.
    def previous_head
      @args[0]
    end

    # Returns the ref of the new current HEAD.
    def new_head
      @args[1]
    end

    # Returns whether this checkout was the result of changing/updating a
    # branch.
    def branch_checkout?
      @args[2].to_i == 1
    end

    # Returns whether this checkout was for a single file.
    def file_checkout?
      !branch_checkout?
    end
  end
end
