require 'forwardable'
require 'overcommit/utils/messages_utils'

module Overcommit::Hook::PreCommit
  # Functionality common to all pre-commit hooks.
  class Base < Overcommit::Hook::Base
    extend Forwardable

    def_delegators :@context, :modified_lines_in_file, :amendment?, :initial_commit?

    private

    def extract_messages(*args)
      Overcommit::Utils::MessagesUtils.extract_messages(*args)
    end
  end
end
