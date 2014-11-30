module Overcommit::Hook::PreCommit
  # Runs `jscs` (JavaScript Code Style Checker) against any modified JavaScript
  # files.
  class Jscs < Base
    def run
      result = execute(%W[#{executable} --reporter=inline] + applicable_files)
      return :pass if result.success?

      if result.status == 1
        # No configuration was found
        return :warn, result.stderr.chomp
      end

      extract_messages(
        result.stdout.split("\n"),
        /^(?<file>[^:]+):[^\d]+(?<line>\d+)/,
      )
    end
  end
end
