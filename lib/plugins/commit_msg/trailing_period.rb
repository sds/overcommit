module Causes::GitHook
  class TrailingPeriod < HookSpecificCheck
    include HookRegistry

    def run_check
      if commit_message[0].rstrip.end_with?('.')
        return :warn, 'Please omit trailing period from commit message subject.'
      end

      :good
    end
  end
end
