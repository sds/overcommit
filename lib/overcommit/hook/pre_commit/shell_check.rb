module Overcommit::Hook::PreCommit
  # Runs `shellcheck` against any modified shell script files.
  class ShellCheck < Base
    MESSAGE_TYPE_CATEGORIZER = lambda do |type|
      type.include?('note') ? :warning : :error
    end

    def run
      result = execute(%W[#{executable} --format=gcc] + applicable_files)
      return :pass if result.success?

      extract_messages(
        result.stdout.split("\n"),
        /^(?<file>[^:]+):(?<line>\d+):[^ ]+ (?<type>[^ ]+)/,
        MESSAGE_TYPE_CATEGORIZER,
      )
    end
  end
end
