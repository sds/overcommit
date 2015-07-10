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

    # Get a list of files that have been added or modified between
    # `previous_head` and `new_head`. Renames and deletions are ignored, since
    # there should be nothing to check.
    def modified_files
      @modified_files ||=
        Overcommit::GitRepo.modified_files(refs: "#{previous_head} #{new_head}")
    end
  end
end
