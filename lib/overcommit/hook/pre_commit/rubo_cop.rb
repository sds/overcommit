module Overcommit::Hook::PreCommit
  # Runs `rubocop` against any modified Ruby files.
  #
  # @see http://batsov.com/rubocop/
  class RuboCop < Base
    MESSAGE_TYPE_CATEGORIZER = lambda do |type|
      type.include?('W') ? :warning : :error
    end

    def run
      result = execute(command, args: applicable_files)
      return :pass if result.success?
      return [:fail, result.stderr] unless result.stderr.empty?

      extract_messages(
        result.stdout.split("\n"),
        /^(?<file>(?:\w:)?[^:]+):(?<line>\d+):[^ ]+ (?<type>[^ ]+)/,
        MESSAGE_TYPE_CATEGORIZER,
      )
    end
  end
end
