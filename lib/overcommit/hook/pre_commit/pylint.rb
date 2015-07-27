module Overcommit::Hook::PreCommit
  # Runs `pylint` against any modified Python files.
  #
  # @see http://www.pylint.org/
  class Pylint < Base
    MESSAGE_REGEX = /^(?<file>(?:\w:)?.+):(?<line>\d+):(?<type>[CEFRW])/

    # Classify 'E' and 'F' message codes as errors,
    # everything else as warnings.
    #   http://pylint.readthedocs.org/en/latest/tutorial.html#getting-started
    MESSAGE_TYPE_CATEGORIZER = lambda do |type|
      'EF'.include?(type) ? :error : :warning
    end

    def run
      result = execute(command, args: applicable_files)
      return :pass if result.success?

      output = result.stdout.chomp

      # example message:
      #   path/to/file.py:64:C: Missing function docstring (missing-docstring)
      extract_messages(
        output.split("\n").grep(MESSAGE_REGEX),
        MESSAGE_REGEX,
        MESSAGE_TYPE_CATEGORIZER
      )
    end
  end
end
