module Overcommit::Hook::PreCommit
  # Runs `mdl` against any modified Markdown files
  #
  # @see https://github.com/mivok/markdownlint
  class Mdl < Base
    MESSAGE_REGEX = /^(?<file>(?:\w:)?[^:]+):(?<line>\d+):\s(?<msg>.+)/

    def run
      result = execute(command, args: applicable_files)
      output = result.stdout.chomp

      return :pass if result.success?
      return [:fail, result.stderr] unless result.stderr.empty?

      # example message:
      #   path/to/file.md:1: MD001 Error message
      extract_messages(
        output.split("\n"),
        MESSAGE_REGEX
      )
    end
  end
end
