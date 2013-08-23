module Overcommit::GitHook
  class PythonFlake8 < HookSpecificCheck
    include HookRegistry
    file_type :py

    def run_check
      unless in_path? 'flake8'
        return :warn, 'Run `pip install flake8`'
      end

      output = `flake8 #{(staged.collect(&:path).join(' '))}`.split("\n")
      return ($?.success? ? :good : :bad), output
    end
  end
end
