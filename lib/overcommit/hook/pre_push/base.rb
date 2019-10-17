# frozen_string_literal: true

require 'forwardable'

module Overcommit::Hook::PrePush
  # Functionality common to all pre-push hooks.
  class Base < Overcommit::Hook::Base
    extend Forwardable

    def_delegators :@context, :remote_name, :remote_url, :pushed_refs

    def skip?
      super ||
        exclude_remote_names.include?(remote_name) ||
        skip_for_remote_branch_deletion?
    end

    private

    def skip_for_remote_branch_deletion?
      ignore_branch_deletions? && @context.remote_branch_deletion?
    end

    def exclude_remote_names
      @config['exclude_remote_names'] || []
    end

    def ignore_branch_deletions?
      @config['ignore_branch_deletions'] != false
    end
  end
end
