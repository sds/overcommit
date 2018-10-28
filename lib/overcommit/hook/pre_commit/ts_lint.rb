# frozen_string_literal: true

module Overcommit::Hook::PreCommit
  # Runs `tslint` against modified TypeScript files.
  # @see http://palantir.github.io/tslint/
  class TsLint < Base
    # example message:
    # "src/file/anotherfile.ts[298, 1]: exceeds maximum line length of 140"
    # or
    # "ERROR: src/AccountController.ts[4, 28]: expected call-signature to have a typedef"
    MESSAGE_REGEX = /^(?<type>.+: )?(?<file>.+?(?=\[))[^\d]+(?<line>\d+).*?/

    def run
      result = execute(command, args: applicable_files)
      output = result.stdout.chomp
      return :pass if result.success? && output.empty?

      output_lines = output.split("\n").map(&:strip).reject(&:empty?)
      type_categorizer = ->(type) { type.nil? || type.include?('ERROR') ? :error : :warning }

      extract_messages(
          output_lines,
          MESSAGE_REGEX,
          type_categorizer
      )
    end
  end
end
