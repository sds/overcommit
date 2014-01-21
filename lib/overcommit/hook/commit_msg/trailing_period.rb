module Overcommit::Hook::CommitMsg
  # Ensures commit message subject lines do not have a trailing period
  class TrailingPeriod < Base
    def run
      if commit_message[0].rstrip.end_with?('.')
        return :warn, 'Please omit trailing period from commit message subject'
      end

      :good
    end
  end
end
