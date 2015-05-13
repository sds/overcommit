module Overcommit::Hook::PreCommit
  # Runs `brakeman` against any modified Ruby/Rails files.
  #
  # @see http://brakemanscanner.org/
  class Brakeman < Base
    def run
      result = execute(command + [applicable_files.join(',')])
      return :pass if result.success?

      [:fail, result.stdout]
    end
  end
end
