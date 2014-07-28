module Overcommit::Hook::PreCommit
  # Checks for hard tabs in files.
  class HardTabs < Base
    def run
      # Catches hard tabs
      result = execute(%w[grep -IHn] + ["\t"] + applicable_files)
      unless result.stdout.empty?
        return :fail, "Hard tabs detected:\n#{result.stdout}"
      end

      :good
    end
  end
end
