require 'forwardable'

module Overcommit::Hook::CommitMsg
  # Functionality common to all commit-msg hooks.
  class Base < Overcommit::Hook::Base
    extend Forwardable

    def_delegators :@context, :commit_message
  end
end
