module Overcommit::Hook::PreCommit
  # Runs 'puppet-lint' against any modified Puppet files.
  #
  # @see http://puppet-lint.com/
  class PuppetLint < Base
    MESSAGE_REGEX = /(?<file>(?:\w:)?.+):(?<line>\d+):\d+:(?<type>\w+)/

    MESSAGE_TYPE_CATEGORIZER = lambda do |type|
      type == 'ERROR' ? :error : :warning
    end

    def run
      result = execute(command, args: applicable_files)
      output = result.stdout.chomp.gsub(/^"|"$/, '')
      return :pass if result.success? && output.empty?

      extract_messages(
        output.split("\n"),
        MESSAGE_REGEX,
        MESSAGE_TYPE_CATEGORIZER
      )
    end
  end
end
