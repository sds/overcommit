# frozen_string_literal: true

module Overcommit::Hook::PreCommit
  # Runs `php -l` against any modified PHP files.
  class PhpLint < Base
    # Sample String
    # rubocop:disable Layout/LineLength
    #   PHP Parse error:  syntax error, unexpected 'require_once' (T_REQUIRE_ONCE) in site/sumo.php on line 12
    # rubocop:enable Layout/LineLength
    MESSAGE_REGEX = /^(?<type>.+)\:\s+(?<message>.+) in (?<file>.+) on line (?<line>\d+)/.freeze

    def run
      # A list of error messages
      messages = []

      # Exit status for all of the runs. Should be zero!
      exit_status_sum = 0

      # Run for each of our applicable files
      applicable_files.each do |file|
        result = execute(command, args: [file])
        output = result.stdout.chomp
        exit_status_sum += result.status
        # `php -l` returns with a leading newline, and we only need the first
        # line, there is usually some redundancy
        messages << output.lstrip.split("\n").first
      end

      # If the sum of all lint status is zero, then none had exit status
      return :pass if exit_status_sum == 0

      # Return the list of message objects
      extract_messages(
        messages,
        MESSAGE_REGEX
      )
    end
  end
end
