module Overcommit::Hook::PreCommit
  # Runs `flake8` against any modified Python files.
  class PythonFlake8 < Base
    # The following regex marks these pyflakes and pep8 codes as errors.
    # All other codes are marked as warnings.
    #
    # Pyflake Errors:
    #  - F402 import module from line N shadowed by loop variable
    #  - F404 future import(s) name after other statements
    #  - F812 list comprehension redefines name from line N
    #  - F823 local variable name ... referenced before assignment
    #  - F831 duplicate argument name in function definition
    #  - F821 undefined name name
    #  - F822 undefined name name in __all__
    #
    # Pep8 Errors:
    #  - E112 expected an indented block
    #  - E113 unexpected indentation
    #  - E901 SyntaxError or IndentationError
    #  - E902 IOError
    ERROR_REGEX = /F(?:40[24]|8(?:12|2[123]|31))|E(?:11[23]|90[12])/

    MESSAGE_REGEX = /^(?<file>.+):(?<line>\d+):\d+:\s(?<type>[FEWCN]\d+)/

    MESSAGE_TYPE_CATEGORIZER = lambda do |type|
      type =~ ERROR_REGEX ? :error : :warning
    end

    def run
      result = execute(command + applicable_files)
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
