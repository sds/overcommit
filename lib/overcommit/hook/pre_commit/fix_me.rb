module Overcommit::Hook::PreCommit
  # Check for "token" strings
  class FixMe < Base
    def run
      keywords = config['keywords']
      result = execute(command, args: [keywords.join('|')] + applicable_files)

      extract_messages(
        result.stdout.split("\n"),
        /^(?<file>(?:\w:)?[^:]+):(?<line>\d+)/,
        lambda { |_type| :warning }
      )
    end
  end
end
