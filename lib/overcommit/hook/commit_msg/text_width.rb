module Overcommit::Hook::CommitMsg
  # Ensures the number of columns the subject and commit message lines occupy is
  # under the preferred limits.
  class TextWidth < Base
    def run
      max_subject_width = @config['max_subject_width']
      max_body_width = @config['max_body_width']

      if commit_message_lines.first.size > max_subject_width
        return :warn, "Please keep the subject <= #{max_subject_width} characters"
      end

      commit_message_lines.each_with_index do |line, index|
        chomped = line.chomp
        if chomped.size > max_body_width
          return :warn, "Line #{index + 1} of commit message has > " <<
                        "#{max_body_width} characters, please hard wrap: " <<
                        "'#{chomped}'"
        end
      end

      :good
    end
  end
end
