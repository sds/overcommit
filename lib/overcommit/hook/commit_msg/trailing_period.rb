module Overcommit::Hook::CommitMsg
  # Ensures commit message subject lines do not have a trailing period
  class TrailingPeriod < Base
    def run
      return :pass if empty_message?

      if commit_message_lines.first.rstrip.end_with?('.')
        return :warn, 'Please omit trailing period from commit message subject'
      end

      :pass
    end
  end
end
