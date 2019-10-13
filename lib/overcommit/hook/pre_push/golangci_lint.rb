# frozen_string_literal: true

module Overcommit::Hook::PrePush
  # Runs golangci-lint
  #
  # @see https://github.com/golangci/golangci-lint
  class GolangciLint < Base
    def run
      result = execute(command)
      return :pass if result.success?

      output = result.stdout + result.stderr
      [:fail, output]
    end
  end
end
