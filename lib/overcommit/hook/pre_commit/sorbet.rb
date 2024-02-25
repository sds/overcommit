# frozen_string_literal: true

module Overcommit::Hook::PreCommit
  # Runs 'srb tc' against any modified files.
  #
  # @see https://github.com/sorbet/sorbet
  class Sorbet < Base
    # example of output:
    # sorbet.rb:1: Method `foo` does not exist on `T.class_of(Bar)` https://srb.help/7003
    MESSAGE_REGEX = /^(?<file>[^:]+):(?<line>\d+): (?<message>.*)$/.freeze

    def run
      result = execute(command, args: applicable_files)
      return :pass if result.success?

      output = result.stderr.split("\n").grep(MESSAGE_REGEX)

      extract_messages(
        output,
        MESSAGE_REGEX
      )
    end
  end
end
