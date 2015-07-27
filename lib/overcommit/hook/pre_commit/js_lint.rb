module Overcommit::Hook::PreCommit
  # Runs `jslint` against any modified JavaScript files.
  #
  # @see http://www.jslint.com/
  class JsLint < Base
    MESSAGE_REGEX = /(?<file>(?:\w:)?[^:]+):(?<line>\d+)/

    def run
      result = execute(command, args: applicable_files)
      return :pass if result.success?

      # example message:
      #   path/to/file.js:1:1: Error message
      extract_messages(
        result.stdout.split("\n").grep(MESSAGE_REGEX),
        MESSAGE_REGEX
      )
    end
  end
end
