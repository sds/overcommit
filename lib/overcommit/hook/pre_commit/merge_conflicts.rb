module Overcommit::Hook::PreCommit
  # Checks for unresolved merge conflicts
  class MergeConflicts < Base
    def run
      result = execute(%w[grep -IHn <<<<<<<] + applicable_files)

      unless result.stdout.empty?
        return :bad, "Merge conflict markers detected:\n#{result.stdout}"
      end

      :good
    end
  end
end
