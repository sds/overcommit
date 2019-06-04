# frozen_string_literal: true

module Overcommit::Hook::PreCommit
  # Runs `stylelint` against any modified CSS file.
  #
  # @see https://github.com/stylelint/stylelint
  class Stylelint < Base
    # example of output:
    # index.css: line 4, col 4, error - Expected indentation of 2 spaces (indentation)

    MESSAGE_REGEX = /^(?<file>.+):\D*(?<line>\d+).*$/

    def run
      result = execute(command, args: applicable_files)
      output = result.stdout.chomp
      return :pass if result.success? && output.empty?
      extract_messages(
        output.split("\n"),
        MESSAGE_REGEX
      )
    end
  end
end
