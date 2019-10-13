# frozen_string_literal: true

module Overcommit::Hook::PreCommit
  # Runs `mdl` against any modified Markdown files
  #
  # @see https://github.com/mivok/markdownlint
  class Mdl < Base
    def run
      result = execute(command, args: applicable_files)
      output = result.stdout.chomp

      return :pass if result.success?
      return [:fail, result.stderr] unless result.stderr.empty?

      # example message:
      #   [{"filename":"file1.md","line":1,"rule":"MD013","aliases":["line-length"],
      #   "description":"Line length"}]
      json_messages = JSON.parse(output)
      json_messages.map do |message|
        Overcommit::Hook::Message.new(
          :error,
          message['filename'],
          message['line'],
          "#{message['filename']}:#{message['line']} #{message['rule']} #{message['description']}"
        )
      end
    end
  end
end
