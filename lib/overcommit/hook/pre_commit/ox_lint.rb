# frozen_string_literal: true

module Overcommit::Hook::PreCommit
  # Runs `oxlint` against any modified JavaScript files.
  #
  # Protip: if you have an npm script set up to run oxlint, you can configure
  # this hook to run oxlint via your npm script by using the `command` option in
  # your .overcommit.yml file. This can be useful if you have some oxlint
  # configuration built into your npm script that you don't want to repeat
  # somewhere else. Example:
  #
  #   OxLint:
  #     required_executable: 'npm'
  #     enabled: true
  #     command: ['npm', 'run', 'lint', '--', '--format=unix']
  #
  # Note: This hook supports only unix format.
  #
  # @see https://oxc.rs
  class OxLint < Base
    def run
      oxlint_regex = %r{^(?:file://)?(?<file>[^:]+):(?<line>\d+):\d+:.*?(?<type>Error|Warning)}
      result = execute(command, args: applicable_files)
      output = result.stdout.chomp
      messages = output.split("\n").grep(oxlint_regex)

      return [:fail, result.stderr] if messages.empty? && !result.success?
      return :pass if result.success? && output.empty?

      # example message:
      #   file://test.js:5:1: `debugger` statement is not allowed [Error/eslint(no-debugger)]
      extract_messages(messages, oxlint_regex, lambda { |type| type.downcase.to_sym })
    end
  end
end
