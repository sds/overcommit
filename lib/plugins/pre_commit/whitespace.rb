module Causes::GitHook
  class Whitespace < HookSpecificCheck
    include HookRegistry

    def run_check
      # Catches trailing whitespace, conflict markers etc
      output = `git diff --check --cached`
      return ($?.exitstatus.zero? ? :good : :stop), output
    end
  end
end
