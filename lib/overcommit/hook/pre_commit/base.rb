require 'forwardable'

module Overcommit::Hook::PreCommit
  # Functionality common to all pre-commit hooks.
  class Base < Overcommit::Hook::Base
    extend Forwardable

    def_delegators :@context, :modified_lines
  end
end
