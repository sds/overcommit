module Overcommit::Hook::PreCommit
  # Runs `eslint` against any modified JavaScript files.
  #
  # @see http://eslint.org/
  class EsLint < Base
    def run
      result = execute(command + applicable_files)
      output = result.stdout.chomp
      return :pass if result.success? && output.empty?

      # example message:
      #   path/to/file.js: line 1, col 0, Error - Error message (ruleName)
      extract_messages(
        output.split("\n").grep(/Warning|Error/),
        /^(?<file>(?:\w:)?[^:]+):[^\d]+(?<line>\d+).*?(?<type>Error|Warning)/,
        lambda { |type| type.downcase.to_sym }
      )
    end
  end
end
