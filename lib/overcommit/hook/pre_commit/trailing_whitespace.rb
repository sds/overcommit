module Overcommit::Hook::PreCommit
  # Checks for trailing whitespace in files.
  class TrailingWhitespace < Base
    def run
      paths = applicable_files.join(' ')

      result = command("grep -IHn \"\\s$\" #{paths}")
      unless result.stdout.empty?
        return :bad, "Trailing whitespace detected:\n#{result.stdout}"
      end

      :good
    end
  end
end
