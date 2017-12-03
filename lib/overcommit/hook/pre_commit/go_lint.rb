module Overcommit::Hook::PreCommit
  # Runs `golint` against any modified Golang files.
  #
  # @see https://github.com/golang/lint
  class GoLint < Base
    def run
      output = ''

      # golint doesn't accept multiple file arguments if
      # they belong to different packages
      applicable_files.each do |gofile|
        result = execute(command, args: Array(gofile))
        output += result.stdout + result.stderr
      end

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
