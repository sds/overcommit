module Overcommit::Hook::PreCommit
  # Runs `golint` against any modified Golang files.
  #
  # @see https://github.com/golang/lint
  class GoLint < Base
    def run
      result = execute(command, args: applicable_files)
      output = result.stdout + result.stderr
      # Unfortunately the exit code is always 0
      return :pass if output.empty?

      # example message:
      #   path/to/file.go:1:1: Error message
      extract_messages(
        output.split("\n"),
        /^(?<file>(?:\w:)?[^:]+):(?<line>\d+)/
      )
    end
  end
end
