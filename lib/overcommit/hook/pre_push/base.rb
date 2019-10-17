# frozen_string_literal: true

require 'forwardable'

module Overcommit::Hook::PrePush
  # Functionality common to all pre-push hooks.
  class Base < Overcommit::Hook::Base
    extend Forwardable

    def_delegators :@context, :remote_name, :remote_url, :pushed_refs

    def run?
      super &&
        !exclude_remotes.include?(remote_name) &&
        (include_branch_deletions? || !@context.remote_branch_deletion?)
    end

    private

    def exclude_remotes
      @config['exclude_remotes'] || []
    end

    def include_branch_deletions?
      @config['include_branch_deletions']
    end
  end
end
