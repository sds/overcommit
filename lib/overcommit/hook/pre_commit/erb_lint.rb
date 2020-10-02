# frozen_string_literal: true

module Overcommit::Hook::PreCommit
  # Runs `erblint` against any modified ERB files.
  #
  # @see https://github.com/Shopify/erb-lint
  class ErbLint < Base
    MESSAGE_REGEX = /(?<message>.+)\nIn file: (?<file>.+):(?<line>\d+)/

    def run
      result = execute(command, args: applicable_files)
      return :pass if result.success?

      extract_messages(
        result.stdout.split("\n\n")[1..-1],
        MESSAGE_REGEX
      )
    end
  end
end
