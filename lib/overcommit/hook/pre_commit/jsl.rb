module Overcommit::Hook::PreCommit
  # Runs `jsl` against any modified JavaScript files.
  #
  # @see http://www.javascriptlint.com/
  class Jsl < Base
    MESSAGE_REGEX = /(?<file>(?:\w:)?.+)\((?<line>\d+)\):(?<type>[^:]+)/

    MESSAGE_TYPE_CATEGORIZER = lambda do |type|
      type =~ /warning/ ? :warning : :error
    end

    def run
      file_flags = applicable_files.map { |file| ['-process', file] }
      result = execute(command + file_flags.flatten)
      return :pass if result.success?

      # example message:
      #   path/to/file.js(1): lint warning: Error message
      extract_messages(
        result.stdout.split("\n").grep(MESSAGE_REGEX),
        MESSAGE_REGEX,
        MESSAGE_TYPE_CATEGORIZER
      )
    end
  end
end
