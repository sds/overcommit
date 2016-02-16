module Overcommit::Hook::CommitMsg
  # Ensures the commit message follows a specific pattern for analytical purposes
  class MsgPattern < Base
    def run
      return :fail, "Empty Message not allowed." if empty_message?

      @errors = []
      validate_pattern(commit_message_lines.join("\n"))
      return :fail, @errors.join("\n") if @errors.any?

      :pass
    end

    private

    def validate_pattern(message)
      pattern = config['pattern']
      expected_pattern_message = config['expected_pattern_message'] || ''
      sample_message = config['sample_message'] || ''
      return if pattern.empty?
      @errors << [
        'Commit message pattern mismatch.',
        "Expected : #{expected_pattern_message}",
        "Sample : #{sample_message}"
      ].join("\n") unless message =~ /#{pattern}/
    end
  end
end
