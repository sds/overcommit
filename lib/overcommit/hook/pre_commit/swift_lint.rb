# frozen_string_literal: true

module Overcommit::Hook::PreCommit
  # Runs `swiftlint lint` against modified Swift files.
  # @see https://github.com/realm/SwiftLint
  class SwiftLint < Base
    MESSAGE_REGEX = /^(?<file>(?:\w:)?[^:]+):(?<line>\d+)[^ ]* (?<type>[^ ]+):(?<message>.*)/

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
