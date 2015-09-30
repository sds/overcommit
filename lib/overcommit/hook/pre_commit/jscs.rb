module Overcommit::Hook::PreCommit
  # Runs `jscs` (JavaScript Code Style Checker) against any modified JavaScript
  # files.
  #
  # @see http://jscs.info/
  class Jscs < Base
    def run
      result = execute(command, args: applicable_files)
      return :pass if result.success?

      # Exit status 2 = Code style errors; everything else we don't know how to
      # parse. https://github.com/jscs-dev/node-jscs/wiki/Exit-codes
      unless result.status == 2
        return :fail, result.stdout + result.stderr.chomp
      end

      # example message:
      #   path/to/file.js: line 7, col 0, ruleName: Error message
      extract_messages(
        result.stdout.split("\n"),
        /^(?<file>(?:\w:)?[^:]+):[^\d]+(?<line>\d+)/,
      )
    end
  end
end
