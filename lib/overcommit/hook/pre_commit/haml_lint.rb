module Overcommit::Hook::PreCommit
  # Runs `haml-lint` against any modified HAML files.
  #
  # @see https://github.com/brigade/haml-lint/
  class HamlLint < Base
    MESSAGE_TYPE_CATEGORIZER = lambda do |type|
      type.include?('W') ? :warning : :error
    end

    def run
      result = execute(command, args: applicable_files)
      return :pass if result.success?

      extract_messages(
        result.stdout.split("\n"),
        /^(?<file>(?:\w:)?[^:]+):(?<line>\d+)[^ ]* (?<type>[^ ]+)/,
        MESSAGE_TYPE_CATEGORIZER,
      )
    end
  end
end
