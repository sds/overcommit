# frozen_string_literal: true

module Overcommit::Hook::PreCommit
  # Runs `golangci-lint run` against any modified packages
  #
  # @see https://github.com/golangci/golangci-lint
  class GolangciLint < Base
    def run
      packages = applicable_files.map { |f| File.dirname(f) }.uniq
      result = execute(command, args: packages)
      return :pass if result.success?
      return [:fail, result.stderr] unless result.stderr.empty?

      extract_messages(
        result.stdout.split("\n"),
        /^(?<file>(?:\w:)?[^:]+):(?<line>\d+)/,
        nil
      )
    end
  end
end
