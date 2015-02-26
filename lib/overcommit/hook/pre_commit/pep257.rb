module Overcommit::Hook::PreCommit
  # Runs `pep257` against any modified Python files.
  class Pep257 < Base
    def run
      result = execute(command + applicable_files)
      return :pass if result.success?

      output = result.stderr.chomp

      # example message:
      #   path/to/file.py:1 in public method `foo`:
      #           D102: Docstring missing
      extract_messages(
        output.gsub(/:\s+/, ': ').split("\n"),
        /^(?<file>[^:]+):(?<line>\d+)/
      )
    end
  end
end
