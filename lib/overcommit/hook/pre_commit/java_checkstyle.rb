module Overcommit::Hook::PreCommit
  # Runs `checkstyle` against any modified Java files.
  #
  # @see http://checkstyle.sourceforge.net/
  class JavaCheckstyle < Base
    MESSAGE_REGEX = /^(?<type>\[[^\]]+\]\s+)?(?<file>(?:\w:)?[^:]+):(?<line>\d+)/

    MESSAGE_TYPE_CATEGORIZER = lambda do |type|
      # Type may be nil if checkstyle doesn't output a 'tag'
      type ||= ''

      type.include?('WARN') || type.include?('INFO') ? :warning : :error
    end

    def run
      result = execute(command, args: applicable_files)
      output = result.stdout.chomp

      # example message:
      #   path/to/file.java:3:5: Error message
      extract_messages(
        output.split("\n").grep(MESSAGE_REGEX),
        MESSAGE_REGEX,
        MESSAGE_TYPE_CATEGORIZER
      )
    end
  end
end
