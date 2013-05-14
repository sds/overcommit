module Causes::GitHook
  class ReleaseNote < HookSpecificCheck
    include HookRegistry

    EMPTY_RELEASE_NOTE = /^release notes?\s*[:.]?\n{2,}/im
    def run_check
      if commit_message.join =~ EMPTY_RELEASE_NOTE
        return :warn, 'Empty release note found, either add one or remove it'
      end

      :good
    end
  end
end
