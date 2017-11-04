require 'forwardable'

module Overcommit::Hook::PrepareCommitMsg
  # Functionality common to all prepare-commit-msg hooks.
  class Base < Overcommit::Hook::Base
    extend Forwardable

    def_delegators :@context,
                   :commit_msg_filename, :commit_msg_source, :commit
  end
end
