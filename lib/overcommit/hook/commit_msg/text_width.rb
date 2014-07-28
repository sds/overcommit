module Overcommit::Hook::CommitMsg
  # Ensures the number of columns the subject and commit message lines occupy is
  # under the preferred limits.
  class TextWidth < Base
    def run
      errors = []

      max_subject_width = @config['max_subject_width']
      max_body_width = @config['max_body_width']

      if commit_message_lines.first.size > max_subject_width
        errors << "Please keep the subject <= #{max_subject_width} characters"
      end

      if commit_message_lines.size > 2
        commit_message_lines[2..-1].each_with_index do |line, index|
          chomped = line.chomp
          if chomped.size > max_body_width
            error = "Line #{index + 3} of commit message has > " \
                    "#{max_body_width} characters"
            errors << error
          end
        end
      end

      return :warn, errors.join("\n") if errors.any?

      :pass
    end
  end
end
