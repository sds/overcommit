module Overcommit::Hook::CommitMsg
  # Ensures the commit message follows a specific format.
  class MessageFormat < Base
    def run
      error_msg = validate_pattern(commit_message_lines.join("\n"))
      return :fail, error_msg if error_msg

      :pass
    end

    private

    def validate_pattern(message)
      pattern = config['pattern']
      return if pattern.empty?

      expected_pattern_message = config['expected_pattern_message']
      sample_message = config['sample_message']

      unless message =~ /#{pattern}/
        [
          'Commit message pattern mismatch.',
          "Expected : #{expected_pattern_message}",
          "Sample : #{sample_message}"
        ].join("\n")
      end
    end
  end
end
