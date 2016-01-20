module Overcommit::Hook::CommitMsg
  # Ensures commit message subject lines start with a capital letter.
  class CapitalizedSubject < Base
    def run
      return :pass if empty_message?

      first_letter = commit_message_lines[0].to_s.match(/^[[:punct:]]*(.)/)[1]
      unless first_letter =~ /[[:upper:]]/
        return :warn, 'Subject should start with a capital letter'
      end

      :pass
    end
  end
end
