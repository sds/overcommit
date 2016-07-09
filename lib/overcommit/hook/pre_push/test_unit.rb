module Overcommit::Hook::PrePush
  # Runs `test-unit` test suite before push
  #
  # @see https://github.com/test-unit/test-unit
  class TestUnit < Base
    def run
      result = execute(command)
      return :pass if result.success?

      output = result.stdout + result.stderr
      [:fail, output]
    end
  end
end
