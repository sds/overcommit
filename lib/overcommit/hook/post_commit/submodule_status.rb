require 'overcommit/hook/shared/submodule_status'

module Overcommit::Hook::PostCommit
  # Checks the status of submodules in the current repository and
  # notifies the user if any are uninitialized, out of date with
  # the current index, or contain merge conflicts.
  class SubmoduleStatus < Base
    include Overcommit::Hook::Shared::SubmoduleStatus
  end
end
