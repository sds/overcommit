module Overcommit::Hook::PreCommit
  # Runs `tslint` against modified TypeScript files.
  # @see http://palantir.github.io/tslint/
  class TsLint < Base
    def run
      result = execute(command, args: applicable_files)
      output = result.stdout.chomp
      return :pass if result.success? && output.empty?

      # example message:
      # src/file/anotherfile.ts[298, 1]: exceeds maximum line length of 140
      extract_messages(
          output.split("\n"),
          /^(?<file>.+?(?=\[))[^\d]+(?<line>\d+).*?/
      )
    end
  end
end
