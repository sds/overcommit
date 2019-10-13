# frozen_string_literal: true

require 'forwardable'

module Overcommit::Hook::PrePush
  # Functionality common to all pre-push hooks.
  class Base < Overcommit::Hook::Base
    extend Forwardable

    def_delegators :@context, :remote_name, :remote_url, :pushed_refs

    def skip?
      super || exclude_remote_names.include?(remote_name)
    end
  end
end
