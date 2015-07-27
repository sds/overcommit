module Overcommit::Hook::PreCommit
  # Runs `flake8` against any modified Python files.
  #
  # @see https://pypi.python.org/pypi/flake8
  class PythonFlake8 < Base
    MESSAGE_REGEX = /^(?<file>(?:\w:)?.+):(?<line>\d+):\d+:\s(?<type>\w\d+)/

    # Classify 'Exxx' and 'Fxxx' message codes as errors,
    # everything else as warnings.
    #   http://flake8.readthedocs.org/en/latest/warnings.html
    MESSAGE_TYPE_CATEGORIZER = lambda do |type|
      'EF'.include?(type[0]) ? :error : :warning
    end

    def run
      result = execute(command, args: applicable_files)
      return :pass if result.success?

      output = result.stdout.chomp

      # example message:
      #   path/to/file.py:2:13: F812 list comprehension redefines name from line 1
      extract_messages(
        output.split("\n").grep(MESSAGE_REGEX),
        MESSAGE_REGEX,
        MESSAGE_TYPE_CATEGORIZER
      )
    end
  end
end
