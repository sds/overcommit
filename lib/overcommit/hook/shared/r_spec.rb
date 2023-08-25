# frozen_string_literal: true

module Overcommit::Hook::Shared
  # Runs `rspec` test suite before push
  #
  # @see http://rspec.info/
  module RSpec
    def run
      result = execute(command)
      return :pass if result.success?

      output = result.stdout + result.stderr
      [:fail, output]
    end
  end
end
