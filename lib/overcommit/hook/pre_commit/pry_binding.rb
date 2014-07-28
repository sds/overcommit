module Overcommit::Hook::PreCommit
  # Adds a check to make sure no `binding.pry`'s have been left in the code
  class PryBinding < Base
    def run
      result = execute(%w[grep -IHnE ^\s*binding\.pry] + applicable_files)

      unless result.stdout.empty?
        return :fail, "Found a `binding.pry` call left in:\n#{result.stdout}"
      end

      :good
    end
  end
end
