module Overcommit::Hook::PreCommit
  # Runs `phpcs` against any modified PHP files.
  class PhpCs < Base
    # Parse `phpcs` csv mode output
    MESSAGE_REGEX = /^\"(?<file>.+)\",(?<line>\d+),\d+,(?<type>.+),\"(?<msg>.+)\"/
    MESSAGE_TYPE_CATEGORIZER = lambda do |type|
      'error'.include?(type) ? :error : :warning
    end

    def run
      messages = []

      applicable_files.each do |file|
        result = execute(command, args: [file])
        if result.status
          rows = result.stdout.split("\n")

          # Discard the csv header
          rows.shift

          # Push each of the errors in the particular file into the array
          rows.map do |row|
            messages << row
          end
        end
      end

      return :pass if messages.empty?

      parse_messages(messages)
    end

    # Transform the CSV output into a tidy human readable message
    def parse_messages(messages)
      output = []

      messages.map do |message|
        message.scan(MESSAGE_REGEX).map do |file, line, type, msg|
          type = MESSAGE_TYPE_CATEGORIZER.call(type)
          text = " #{file}:#{line}\n  #{msg}"
          output << Overcommit::Hook::Message.new(type, file, line.to_i, text)
        end
      end

      output
    end
  end
end
