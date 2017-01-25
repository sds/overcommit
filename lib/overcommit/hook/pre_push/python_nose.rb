module Overcommit::Hook::PrePush
  # Runs `nose` test suite before push
  #
  # @see https://nose.readthedocs.io/en/latest/
  class PythonNose < Base
    def run
      result = execute(command)
      return :pass if result.success?

      output = result.stdout + result.stderr
      [:fail, output]
    end
  end
end
