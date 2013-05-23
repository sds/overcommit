module Overcommit::GitHook
  class JSConsoleLog < HookSpecificCheck
    include HookRegistry
    file_type :js

    # https://www.pivotaltracker.com/story/show/18119495
    def run_check
      paths = staged.join(' ')
      output = `grep -n -e 'console\\.log' #{paths}`.split("\n").reject do |line|
        /^\d+:\s*\/\// =~ line ||     # Skip comments
          /ALLOW_CONSOLE_LOG/ =~ line # and lines with ALLOW_CONSOLE_LOG
      end.join("\n")
      return (output.empty? ? :good : :bad), output
    end
  end
end
