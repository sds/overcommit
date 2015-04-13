module Overcommit::Hook::PreCommit
  # Runs `vint` against any modified Vim script files.
  class Vint < Base
    def run
      result = execute(command + applicable_files)
      return :pass if result.success?

      return [:fail, result.stderr] unless result.stderr.empty?

      # example message:
      #   path/to/file.vim:1:1: Error message
      extract_messages(
        result.stdout.split("\n"),
        /^(?<file>[^:]+):(?<line>\d+)/
      )
    end
  end
end
