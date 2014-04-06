module Overcommit::Hook::PreCommit
  # Adds a check to make sure no `binding.pry`'s have been left in the code
  class PryBindingCheck < Base
    def run
      result = execute(%w[grep -IHn] + ['^\s*binding\.pry'] + applicable_files)

      unless result.stdout.empty?
        return :bad, "Found a binding.pry left in:\n#{result.stdout}"
      end

      :good
    end
  end
end
