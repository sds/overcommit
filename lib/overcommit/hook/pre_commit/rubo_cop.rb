module Overcommit::Hook::PreCommit
  # Runs `rubocop` against any modified Ruby files.
  #
  # @see http://batsov.com/rubocop/
  class RuboCop < Base
    GENERIC_MESSAGE_TYPE_CATEGORIZER = lambda do |type|
      type =~ /^warn/ ? :warning : :error
    end

    COP_MESSAGE_TYPE_CATEGORIZER = lambda do |type|
      type.include?('W') ? :warning : :error
    end

    def run
      result = execute(command, args: applicable_files)
      return :pass if result.success?

      generic_messages = extract_messages(
        result.stderr.split("\n"),
        /^(?<type>[a-z]+)/i,
        GENERIC_MESSAGE_TYPE_CATEGORIZER,
      )

      cop_messages = extract_messages(
        result.stdout.split("\n"),
        /^(?<file>(?:\w:)?[^:]+):(?<line>\d+):[^ ]+ (?<type>[^ ]+)/,
        COP_MESSAGE_TYPE_CATEGORIZER,
      )

      generic_messages + cop_messages
    end
  end
end
