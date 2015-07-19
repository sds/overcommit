module Overcommit::Hook::PreCommit
  # Checks for hard tabs in files.
  class HardTabs < Base
    def run
      result = execute(command, args: applicable_files)

      extract_messages(
        result.stdout.split("\n"),
        /^(?<file>(?:\w:)?[^:]+):(?<line>\d+)/,
      )
    end
  end
end
