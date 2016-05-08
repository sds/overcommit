module Overcommit::Hook::CommitMsg
  # Ensures commit message subject lines start with a capital letter.
  class CapitalizedSubject < Base
    def run
      return :pass if empty_message?

      subject = commit_message_lines[0].to_s
      first_letter = subject.match(/^[[:punct:]]*(.)/)[1]
      unless special_prefix?(subject) || first_letter =~ /[[:upper:]]/
        return :warn, 'Subject should start with a capital letter'
      end

      :pass
    end

    private

    def special_prefix?(subject)
      subject =~ /^(fixup|squash)!/
    end
  end
end
