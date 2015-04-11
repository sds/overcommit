module Overcommit::Hook::PrePush
  # Runs `rspec` test suite before push
  class RSpec < Base
    def run
      result = execute(command)
      return :pass if result.success?

      output = result.stdout + result.stderr
      [:fail, output]
    end
  end
end
