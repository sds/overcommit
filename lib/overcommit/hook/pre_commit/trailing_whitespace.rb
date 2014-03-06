module Overcommit::Hook::PreCommit
  # Checks for trailing whitespace in files.
  class TrailingWhitespace < Base
    def run
      result = execute(%w[grep -IHn \s$] + applicable_files)
      unless result.stdout.empty?
        return :bad, "Trailing whitespace detected:\n#{result.stdout}"
      end

      :good
    end
  end
end
