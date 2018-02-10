module Overcommit::Hook::PrePush
  # Runs `phpunit` test suite before push
  #
  # @see https://phpunit.de/
  class PhpUnit < Base
    def run
      result = execute(command)
      return :pass if result.success?

      output = result.stdout + result.stderr
      [:fail, output]
    end
  end
end
