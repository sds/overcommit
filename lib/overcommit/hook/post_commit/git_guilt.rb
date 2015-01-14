module Overcommit::Hook::PostCommit
  # Calculates the change in blame since the last revision.
  class GitGuilt < Base
    def run
      system(executable, 'HEAD~', 'HEAD')
      :pass
    end
  end
end
