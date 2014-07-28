module Overcommit::Hook::PreCommit
  # Checks for unresolved merge conflicts
  class MergeConflicts < Base
    def run
      result = execute(%w[grep -IHn ^<<<<<<<\s] + applicable_files)

      unless result.stdout.empty?
        return :fail, "Merge conflict markers detected:\n#{result.stdout}"
      end

      :pass
    end
  end
end
