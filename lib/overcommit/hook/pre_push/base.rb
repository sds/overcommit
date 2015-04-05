require 'forwardable'

module Overcommit::Hook::PrePush
  # Functionality common to all pre-push hooks.
  class Base < Overcommit::Hook::Base
    extend Forwardable

    def_delegators :@context, :remote_name, :remote_url, :pushed_refs
  end
end
