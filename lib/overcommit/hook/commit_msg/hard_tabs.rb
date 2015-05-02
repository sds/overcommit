module Overcommit::Hook::CommitMsg
  # Checks for hard tabs in commit messages.
  class HardTabs < Base
    def run
      return :pass if empty_message?

      # Catches hard tabs entered by the user (not auto-generated)
      if commit_message.index(/\t/)
        return :warn, "Don't use hard tabs in commit messages"
      end

      :pass
    end
  end
end
