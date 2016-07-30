module Overcommit::Hook::CommitMsg
  # Check that a commit message conforms to a certain style
  class Commitplease < Base
    def run
      result = execute(command)
      output = result.stderr
      return :pass if result.success? && output.empty?

      [:fail, output]
    end
  end
end
