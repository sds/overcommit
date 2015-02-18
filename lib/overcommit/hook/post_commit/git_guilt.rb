module Overcommit::Hook::PostCommit
  # Calculates the change in blame since the last revision.
  class GitGuilt < Base
    def run
      return :pass unless previous_commit?
      result = execute([required_executable, 'HEAD~', 'HEAD'])
      puts result.stdout
      :pass
    end
  end
end
