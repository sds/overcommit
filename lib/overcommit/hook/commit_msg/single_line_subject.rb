module Overcommit::Hook::CommitMsg
  # Ensures commit message subject lines are followed by a blank line.
  class SingleLineSubject < Base
    def run
      unless commit_message[1].to_s.strip.empty?
        return :warn, 'Subject should be one line and followed by a blank line'
      end

      :good
    end
  end
end
