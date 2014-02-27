module Overcommit::Hook::CommitMsg
  # Ensures the number of columns the subject and commit message lines occupy is
  # under the preferred limits.
  class TextWidth < Base
    def run
      subject_length = @config['subject_length']
      commit_message_length = @config['commit_message_length']

      if commit_message_lines.first.size > subject_length
        return :warn, "Please keep the subject < ~#{subject_length} characters"
      end

      commit_message_lines.each do |line|
        chomped = line.chomp
        if chomped.size > commit_message_length
          return :warn, "> #{commit_message_length} characters, " <<
                        "please hard wrap: '#{chomped}'"
        end
      end

      :good
    end
  end
end
