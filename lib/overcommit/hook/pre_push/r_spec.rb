# frozen_string_literal: true

require 'overcommit/hook/shared/r_spec'

module Overcommit::Hook::PrePush
  # Runs `rspec` test suite
  #
  # @see http://rspec.info/
  class RSpec < Base
    include Overcommit::Hook::Shared::RSpec
  end
end
