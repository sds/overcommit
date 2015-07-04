module Overcommit::Hook::PreCommit
  # Checks for trailing whitespace in files.
  class TrailingWhitespace < Base
    def run
      result = execute(command, applicable_files)

      extract_messages(
        result.stdout.split("\n"),
        /^(?<file>[^:]+):(?<line>\d+)/,
      )
    end
  end
end
