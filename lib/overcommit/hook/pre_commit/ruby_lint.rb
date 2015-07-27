module Overcommit::Hook::PreCommit
  # Runs `ruby-lint` against any modified Ruby files.
  #
  # @see https://github.com/YorickPeterse/ruby-lint
  class RubyLint < Base
    MESSAGE_TYPE_CATEGORIZER = lambda do |type|
      type.include?('W') ? :warning : :error
    end

    def run
      result = execute(command, args: applicable_files)
      return :pass if result.success?

      extract_messages(
        result.stdout.split("\n"),
        /^(?<file>(?:\w:)?[^:]+):(?<type>[^:]+):(?<line>\d+)/,
        MESSAGE_TYPE_CATEGORIZER
      )
    end
  end
end
