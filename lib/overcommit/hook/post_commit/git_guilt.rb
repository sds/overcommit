module Overcommit::Hook::PostCommit
  # Calculates the change in blame since the last revision.
  class GitGuilt < Base
    def run
      result = execute([required_executable, 'HEAD~', 'HEAD'])
      puts result.stdout
      :pass
    end
  end
end
