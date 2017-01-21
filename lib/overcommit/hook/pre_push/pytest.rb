module Overcommit::Hook::PrePush
  # Runs `pytest` test suite before push
  #
  # @see https://github.com/pytest-dev/pytest
  class Pytest < Base
    def run
      result = execute(command)
      return :pass if result.success?

      output = result.stdout + result.stderr
      [:fail, output]
    end
  end
end
