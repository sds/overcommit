module Overcommit::Hook::PreCommit
  # Checks for hard tabs in files.
  class HardTabs < Base
    def run
      paths = applicable_files.join(' ')

      # Catches hard tabs
      result = command("grep -IHn \"\\t\" #{paths}")
      unless result.stdout.empty?
        return :bad, "Hard tabs detected:\n#{result.stdout}"
      end

      :good
    end
  end
end
