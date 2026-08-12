# frozen_string_literal: true

module Overcommit::Hook::PreCommit
  # Runs `herb-lint` against any modified ERB files.
  #
  # @see https://herb-tools.dev/projects/linter
  class HerbLint < Base
    def run
      result = execute(command + ['--json'], args: applicable_files)
      return :pass if result.success?

      json_output = JSON.parse(result.stdout)
      json_output['offenses'].map do |offense|
        severity = offense['severity'] == 'error' ? :error : :warning
        filename = offense['filename']
        line = offense['location']['start']['line']
        message = offense['message']
        code = offense['code']

        Overcommit::Hook::Message.new(
          severity, filename, line,
          "#{filename}:#{line} #{code} #{message}"
        )
      end
    end
  end
end
