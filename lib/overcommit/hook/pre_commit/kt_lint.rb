# frozen_string_literal: true

module Overcommit::Hook::PreCommit
  # Runs `ktlint` against modified Kotlin files.
  # @see https://github.com/shyiko/ktlint
  class KtLint < Base
    MESSAGE_REGEX = /((?<file>[^:]+):(?<line>\d+):(\d+):(?<message>.+))/

    def run
      result = execute(command, args: applicable_files)
      return :pass if result.success?

      extract_messages(
        result.stdout.split("\n").grep(MESSAGE_REGEX),
        MESSAGE_REGEX
      )
    end
  end
end
