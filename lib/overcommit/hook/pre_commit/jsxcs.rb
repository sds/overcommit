module Overcommit::Hook::PreCommit
  # Runs `jsxcs` (JSCS (JavaScript Code Style Checker) wrapper for JSX files)
  # against any modified JavaScript files.
  class Jsxcs < Base
    def run
      result = execute(%W[#{executable} --reporter=inline] + applicable_files)
      return :pass if result.success?

      if result.status == 1
        # No configuration found
        return :warn, result.stderr.chomp
      end

      extract_messages(
        result.stdout.split("\n"),
        /^(?<file>[^:]+):[^\d]+(?<line>\d+)/,
      )
    end
  end
end
