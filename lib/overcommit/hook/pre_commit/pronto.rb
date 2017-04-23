module Overcommit::Hook::PreCommit
  # Runs `pronto`
  #
  # @see https://github.com/mmozuras/pronto
  class Pronto < Base
    MESSAGE_TYPE_CATEGORIZER = lambda do |type|
      type.include?('E') ? :error : :warning
    end

    def run
      result = execute(command)
      return :pass if result.success?

      extract_messages(
        result.stdout.split("\n"),
        /^(?<file>(?:\w:)?[^:]+):(?<line>\d+) (?<type>[^ ]+)/,
        MESSAGE_TYPE_CATEGORIZER,
      )
    end
  end
end
