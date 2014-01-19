module Overcommit::Hook::PreCommit
  # Runs `flake8` against any modified Python files.
  class PythonFlake8 < Base
    def run
      return :warn, 'Run `pip install flake8`' unless in_path?('flake8')

      result = command("flake8 #{applicable_files.join(' ')}")

      return (result.success? ? :good : :bad), result.stdout
    end
  end
end
