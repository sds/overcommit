module Overcommit::Hook::PreCommit
  # Runs `eslint` against any modified JavaScript files.
  #
  # Protip: if you have an npm script set up to run eslint, you can configure
  # this hook to run eslint via your npm script by using the `command` option in
  # your .overcommit.yml file. This can be useful if you have some eslint
  # configuration built into your npm script that you don't want to repeat
  # somewhere else. Example:
  #
  #   EsLint:
  #     required_executable: 'npm'
  #     enabled: true
  #     command: ['npm', 'run', 'lint', '--', '-f', 'compact']
  #
  # Note: This hook supports only compact format.
  #
  # @see http://eslint.org/
  class EsLint < Base
    def run
      result = execute(command, args: applicable_files)
      output = result.stdout.chomp
      messages = output.split("\n").grep(/Warning|Error/)

      return [:fail, result.stderr] if messages.empty? && !result.success?
      return :pass if result.success? && output.empty?

      # example message:
      #   path/to/file.js: line 1, col 0, Error - Error message (ruleName)
      extract_messages(
        messages,
        /^(?<file>(?:\w:)?[^:]+):[^\d]+(?<line>\d+).*?(?<type>Error|Warning)/,
        lambda { |type| type.downcase.to_sym }
      )
    end
  end
end
