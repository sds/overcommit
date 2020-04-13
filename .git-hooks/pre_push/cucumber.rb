# frozen_string_literal: true

module Overcommit::Hook::PrePush
  # Runs `cucumber` test suite before push
  class Cucumber < Base
    def run
      command ||= ['bundle', 'exec', 'cucumber']

      result = execute(command)
      return :pass if result.success?

      output = result.stdout + result.stderr
      [:fail, output]
    end
  end
end
