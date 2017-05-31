module Overcommit::Hook::PreCommit
  # Runs `pydocstyle` against any modified Python files.
  #
  # @see https://pypi.python.org/pypi/pydocstyle
  class Pydocstyle < Base
    def run
      result = execute(command, args: applicable_files)
      return :pass if result.success?

      output = result.stderr.chomp

      # example message:
      #   path/to/file.py:1 in public method `foo`:
      #           D102: Docstring missing
      extract_messages(
        output.gsub(/:\s+/, ': ').split("\n"),
        /^(?<file>(?:\w:)?[^:]+):(?<line>\d+)/
      )
    end
  end
end
