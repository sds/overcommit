module Overcommit::Hook::PreCommit
  # Runs `pep8` against any modified Python files.
  #
  # @see https://pypi.python.org/pypi/pep8
  class Pep8 < Base
    def run
      result = execute(command, args: applicable_files)
      output = result.stdout.chomp

      return :pass if result.success? && output.empty?

      # example message:
      #   path/to/file.py:88:5: E301 expected 1 blank line, found 0
      extract_messages(
        output.split("\n"),
        /^(?<file>(?:\w:)?[^:]+):(?<line>\d+):\d+:\s(?<type>E|W)/,
        lambda { |type| type.include?('W') ? :warning : :error }
      )
    end
  end
end
