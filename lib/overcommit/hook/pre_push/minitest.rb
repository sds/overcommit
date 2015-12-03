module Overcommit::Hook::PrePush
  # Runs `minitest` test suite before push
  #
  # @see https://github.com/seattlerb/minitest
  class Minitest < Base
    def run
      result = execute(command)
      return :pass if result.success?

      output = result.stdout + result.stderr
      [:fail, output]
    end
  end
end
