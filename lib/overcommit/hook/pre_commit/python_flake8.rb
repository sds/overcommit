module Overcommit::Hook::PreCommit
  # Runs `flake8` against any modified Python files.
  class PythonFlake8 < Base
    def run
      result = execute([executable] + applicable_files)
      return :pass if result.success?

      [:fail, result.stdout]
    end
  end
end
