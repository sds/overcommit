require 'forwardable'

module Overcommit::Hook::PostCheckout
  # Functionality common to all post-checkout hooks.
  class Base < Overcommit::Hook::Base
    extend Forwardable

    def_delegators :@context,
                   :previous_head, :new_head, :branch_checkout?, :file_checkout?

    def skip_file_checkout?
      @config['skip_file_checkout'] != false
    end

    def enabled?
      return false if file_checkout? && skip_file_checkout?
      super
    end
  end
end
