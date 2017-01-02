module Overcommit::Hook::PostCommit
  # Check that a commit message conforms to a certain style
  #
  # @see https://www.npmjs.com/package/commitplease
  class Commitplease < Base
    def run
      result = execute(command)
      output = result.stderr
      return :pass if result.success? && output.empty?

      [:fail, output]
    end
  end
end
