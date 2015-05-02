require 'forwardable'

module Overcommit::Hook::CommitMsg
  # Functionality common to all commit-msg hooks.
  class Base < Overcommit::Hook::Base
    extend Forwardable

    def_delegators :@context, :empty_message?, :commit_message,
                   :update_commit_message, :commit_message_lines,
                   :commit_message_file
  end
end
