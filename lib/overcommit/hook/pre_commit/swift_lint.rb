module Overcommit::Hook::PreCommit
  # Runs `swiftlint lint` against modified Swift files.
  # @see https://github.com/realm/SwiftLint
  class SwiftLint < Base
    MESSAGE_REGEX = /^(?<file>(?:\w:)?[^:]+):(?<line>\d+)[^ ]* (?<type>[^ ]+):(?<message>.*):/

    MESSAGE_TYPE = lambda do |type|
      type.include?('warning') ? :warning : :error
    end

    def run
      result = execute(command, args: applicable_files)
      output = result.stdout.split("\n").map { |message| [message.match(MESSAGE_REGEX)].join.chomp(':') }

      return :pass if result.success? && output.empty?

      # example message:
      #   path/to/file.swift:1: Error type: Error message: details
      extract_messages(
        output,
        MESSAGE_REGEX,
        MESSAGE_TYPE
      )
    end
  end
end
