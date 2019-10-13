# frozen_string_literal: true

module Overcommit::Hook::PrePush
  # Runs `go test ./...` command on prepush
  class GoTest < Base
    def run
      result = execute(command)
      return :pass if result.success?

      output = result.stdout + result.stderr
      [:fail, output]
    end
  end
end
