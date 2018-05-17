module Overcommit::Hook::PreCommit
  # Runs `php-cs-fixer` against any modified PHP files.
  class PhpCsFixer < Base
    MESSAGE_REGEX = /\s+\d+\)\s+(?<file>.*\.php)(?<violated_rules>\s+\(\w+(?:,\s+)?\))?/

    def run
      messages = []
      feedback = ''

      # Exit status for all of the runs. Should be zero!
      exit_status_sum = 0

      applicable_files.each do |file|
        result = execute(command, args: [file])
        output = result.stdout.chomp
        exit_status_sum += result.status

        if result.status
          messages = output.lstrip.split("\n")
        end
      end

      unless messages.empty?
        feedback = parse_messages(messages)
      end

      :pass if exit_status_sum == 0
      :pass if feedback.empty?

      feedback
    end

    def parse_messages(messages)
      output = []

      messages.map do |message|
        message.scan(MESSAGE_REGEX).map do |file, violated_rules|
          type = :error
          unless violated_rules.nil?
            type = :warning
          end
          text = if type == :error
                   "Cannot process #{file}: Syntax error"
                 else
                   "#{file} has been fixed"
                 end

          output << Overcommit::Hook::Message.new(type, file, 0, text)
        end
      end

      output
    end
  end
end
