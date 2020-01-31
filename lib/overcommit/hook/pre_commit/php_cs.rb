# frozen_string_literal: true

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

      result = execute(command, args: applicable_files)
      if result.status
        messages = result.stdout.split("\n")
        # Discard the csv header
        messages.shift
      end

      return :fail if messages.empty? && !result.success?
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
