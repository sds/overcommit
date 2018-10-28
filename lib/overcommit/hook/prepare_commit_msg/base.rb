# frozen_string_literal: true

require 'forwardable'

module Overcommit::Hook::PrepareCommitMsg
  # Functionality common to all prepare-commit-msg hooks.
  class Base < Overcommit::Hook::Base
    extend Forwardable

    def_delegators :@context,
                   :commit_message_filename, :commit_message_source, :commit, :lock

    def modify_commit_message
      raise 'This expects a block!' unless block_given?
      # NOTE: this assumes all the hooks of the same type share the context's
      # memory. If that's not the case, this won't work.
      lock.synchronize do
        contents = File.read(commit_message_filename)
        File.open(commit_message_filename, 'w') do |f|
          f << (yield contents)
        end
      end
    end
  end
end
