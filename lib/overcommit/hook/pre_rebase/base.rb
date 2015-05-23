require 'forwardable'

module Overcommit::Hook::PreRebase
  # Functionality common to all pre-rebase hooks.
  class Base < Overcommit::Hook::Base
    extend Forwardable

    def_delegators :@context,
                   :upstream_branch, :rebased_branch, :detached_head?,
                   :fast_forward?, :rebased_commits
  end
end
