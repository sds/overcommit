module Overcommit::Hook::PreCommit
  # Runs `hlint` against any modified Haskell files.
  #
  # @see https://github.com/ndmitchell/hlint
  class Hlint < Base
    MESSAGE_REGEX = /
      ^(?<file>(?:\w:)?[^:]+)
      :(?<line>\d+)
      :\d+
      :\s*(?<type>\w+)
    /x

    MESSAGE_TYPE_CATEGORIZER = lambda do |type|
      type.include?('W') ? :warning : :error
    end

    def run
      result = execute(command, args: applicable_files)
      return :pass if result.success?

      raw_messages = result.stdout.split("\n").grep(MESSAGE_REGEX)

      # example message:
      #   path/to/file.hs:1:0: Error: message
      extract_messages(
        raw_messages,
        MESSAGE_REGEX,
        MESSAGE_TYPE_CATEGORIZER
      )
    end
  end
end
