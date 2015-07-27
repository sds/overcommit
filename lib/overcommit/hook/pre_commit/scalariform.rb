module Overcommit::Hook::PreCommit
  # Runs `scalariform` against any modified Scala files.
  #
  # @see https://github.com/mdr/scalariform
  class Scalariform < Base
    MESSAGE_REGEX = /^\[(?<type>FAILED|ERROR)\]\s+(?<file>(?:\w:)?.+)/

    def run
      result = execute(command, args: applicable_files)

      # example message:
      #   [FAILED] path/to/file.scala
      extract_messages(
        result.stdout.split("\n").grep(MESSAGE_REGEX),
        MESSAGE_REGEX,
        lambda { |type| type == 'ERROR' ? :error : :warning }
      )
    end
  end
end
