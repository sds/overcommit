module Overcommit::Hook::CommitMsg
  # Checks for hard tabs in commit messages.
  class HardTabs < Base
    def run
      # Catches hard tabs entered by the user (not auto-generated)
      if commit_message.join.index(/\t/)
        return :warn, "Don't use hard tabs in commit messages"
      end

      :good
    end
  end
end
