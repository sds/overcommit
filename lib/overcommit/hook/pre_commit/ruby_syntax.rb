# frozen_string_literal: true

module Overcommit::Hook::PreCommit
  # Runs `ruby -c` against all Ruby files.
  #
  class RubySyntax < Base
    MESSAGE_TYPE_CATEGORIZER = lambda do |type|
      type.match?(/^(syntax)?\s*error/) ? :error : :warning
    end

    def run
      result = execute(command, args: applicable_files)

      result_lines = result.stderr.split("\n")

      return :pass if result_lines.length.zero?

      # Example message:
      #   path/to/file.rb:1: syntax error, unexpected '^'
      extract_messages(
        result_lines,
        /^(?<file>[^:]+):(?<line>\d+):\s*(?<type>[^,]+),\s*(?<message>.+)/,
        MESSAGE_TYPE_CATEGORIZER
      )
    end
  end
end
