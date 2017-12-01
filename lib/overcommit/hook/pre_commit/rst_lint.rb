module Overcommit::Hook::PreCommit
  # Runs `rst-lint` against any modified reStructuredText files
  #
  # @see https://github.com/twolfson/restructuredtext-lint
  class RstLint < Base
    MESSAGE_REGEX = /
    ^(?<type>INFO|WARNING|ERROR|SEVERE)(?<file>(?:\w:)?[^:]+):(?<line>\d+)\s(?<msg>.+)
    /x

    def run
      result = execute(command, args: applicable_files)
      output = result.stdout.chomp

      return :pass if result.success?
      return [:fail, result.stderr] unless result.stderr.empty?

      # example message:
      # WARNING README.rst:7 Title underline too short.
      extract_messages(
        output.split("\n"),
        MESSAGE_REGEX
      )
    end
  end
end
