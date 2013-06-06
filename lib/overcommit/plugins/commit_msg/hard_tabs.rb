module Overcommit::GitHook
  class HardTabs < HookSpecificCheck
    include HookRegistry

    def run_check
      # Catches hard tabs
      if commit_message.join.index /\t/
        return :warn, "Don't use hard tabs in commit messages."
      end

      :good
    end
  end
end
