module Overcommit::Hook::CommitMsg
  # Ensures commit message subject lines start with a capital letter.
  class CapitalizedSubject < Base
    def run
      return :pass if empty_message?

      # Git treats the first non-empty line as the subject
      subject = commit_message_lines.find { |line| !line.strip.empty? }.to_s
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
