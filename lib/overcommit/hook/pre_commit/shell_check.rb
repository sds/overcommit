module Overcommit::Hook::PreCommit
  # Runs `shellcheck` against any modified shell script files.
  #
  # @see http://www.shellcheck.net/
  class ShellCheck < Base
    MESSAGE_TYPE_CATEGORIZER = lambda do |type|
      type.include?('note') ? :warning : :error
    end

    def run
      result = execute(command, args: applicable_files)
      return :pass if result.success?

      extract_messages(
        result.stdout.split("\n"),
        /^(?<file>(?:\w:)?[^:]+):(?<line>\d+):[^ ]+ (?<type>[^ ]+)/,
        MESSAGE_TYPE_CATEGORIZER,
      )
    end
  end
end
