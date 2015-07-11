require 'forwardable'

module Overcommit::Hook::PostRewrite
  # Functionality common to all post-rewrite hooks.
  class Base < Overcommit::Hook::Base
    extend Forwardable

    def_delegators :@context, :amend?, :rebase?, :rewritten_commits
  end
end
