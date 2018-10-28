# frozen_string_literal: true

module Overcommit::Hook::PreCommit
  # Checks for trailing whitespace in files.
  class TrailingWhitespace < Base
    def run
      result = execute(command, args: applicable_files)

      extract_messages(
        result.stdout.split("\n"),
        /^(?<file>(?:\w:)?[^:]+):(?<line>\d+)/,
      )
    end
  end
end
