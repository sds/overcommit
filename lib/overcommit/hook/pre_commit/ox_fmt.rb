# frozen_string_literal: true

module Overcommit::Hook::PreCommit
  # Runs `oxfmt` against any modified files.
  #
  # Protip: if you have an npm script set up to run oxfmt, you can configure
  # this hook to run oxfmt via your npm script by using the `command` option in
  # your .overcommit.yml file. This can be useful if you have some oxfmt
  # configuration built into your npm script that you don't want to repeat
  # somewhere else. Example:
  #
  #   oxfmt:
  #     required_executable: 'npm'
  #     enabled: true
  #     command: ['npm', 'run', 'fmt', '--', '--check']
  #
  # Note: This hook only supports check mode.
  #
  # @see https://oxc.rs
  class OxFmt < Base
    def run
      oxfmt_regex = /^(?<file>.+) \(\d+ms\)/
      result = execute(command, args: applicable_files)
      output = result.stdout.chomp
      messages = output.split("\n").grep(oxfmt_regex)

      return [:fail, result.stderr] if messages.empty? && !result.success?
      return :pass if result.success? && output.empty?

      # example message:
      #   test.js (5ms)
      extract_messages(messages, oxfmt_regex)
    end
  end
end
