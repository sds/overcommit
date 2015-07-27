module Overcommit::Hook::PreCommit
  # Runs `vint` against any modified Vim script files.
  #
  # @see https://github.com/Kuniwak/vint
  class Vint < Base
    def run
      result = execute(command, args: applicable_files)
      return :pass if result.success?

      return [:fail, result.stderr] unless result.stderr.empty?

      # example message:
      #   path/to/file.vim:1:1: Error message
      extract_messages(
        result.stdout.split("\n"),
        /^(?<file>(?:\w:)?[^:]+):(?<line>\d+)/
      )
    end
  end
end
