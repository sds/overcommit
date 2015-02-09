module Overcommit::Hook::PreCommit
  # Runs `brakeman` against any modified Ruby/Rails files.
  class Brakeman < Base
    def run
      result = execute(command + [applicable_files.join(',')])
      return :pass if result.success?

      [:fail, result.stdout]
    end
  end
end
