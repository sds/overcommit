require 'forwardable'

module Overcommit::Hook::PostCheckout
  # Functionality common to all post-checkout hooks.
  class Base < Overcommit::Hook::Base
    extend Forwardable

    def_delegators :@context,
                   :previous_head, :new_head, :branch_checkout?, :file_checkout?
  end
end
