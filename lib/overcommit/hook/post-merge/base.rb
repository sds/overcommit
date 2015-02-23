require 'forwardable'

module Overcommit::Hook::PostMerge
  # Functionality common to all post-merge hooks.
  class Base < Overcommit::Hook::Base
    extend Forwardable

    def_delegators :@context, :modified_lines_in_file, :squash?, :merge_commit?
  end
end
