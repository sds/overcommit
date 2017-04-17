module Overcommit::Hook::PreCommit
  # Runs `recess` against any modified CSS files.
  #
  # @see https://twitter.github.io/recess/
  class Recess < Base
    MESSAGE_REGEX = /^(?<file>(?:\w:)?[^:]+):(?<line>\d+):.+$/

    def run
      result = execute(command, args: applicable_files)

      raw_messages = result.stdout.split("\n").grep(MESSAGE_REGEX)

      # example message:
      #   path/to/file.css:1:Error message
      extract_messages(raw_messages, MESSAGE_REGEX)
    end
  end
end
