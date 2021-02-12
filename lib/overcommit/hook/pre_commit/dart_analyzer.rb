# frozen_string_literal: true

module Overcommit::Hook::PreCommit
  # Runs `dartanalyzer` against modified Dart files.
  # @see https://dart.dev/tools/dartanalyzer
  class DartAnalyzer < Base
    MESSAGE_REGEX = /(?<type>.*)•\ (?<message>[^•]+)•\ (?<file>[^:]+):(?<line>\d+):(\d+)\.*/

    def run
      result = execute(command, args: applicable_files)
      return :pass if result.success?

      extract_messages(
        result.stdout.split("\n").grep(MESSAGE_REGEX),
        MESSAGE_REGEX,
        lambda do |type|
          type.include?('error') ? :error : :warning
        end
      )
    end
  end
end
