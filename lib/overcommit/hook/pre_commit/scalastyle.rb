module Overcommit::Hook::PreCommit
  # Runs `scalastyle` against any modified Scala files.
  #
  # @see http://www.scalastyle.org/
  class Scalastyle < Base
    MESSAGE_REGEX = /
      ^(?<type>error|warning)\s
      file=(?<file>.+)\s
      message=.+\s
      line=(?<line>\d+)
    /x

    def run
      result = execute(command + applicable_files)
      output = result.stdout.chomp
      messages = output.split("\n").grep(MESSAGE_REGEX)
      return :pass if result.success? && messages.empty?

      # example message:
      #   error file=/path/to/file.scala message=Error message line=1 column=1
      extract_messages(
        messages,
        MESSAGE_REGEX,
        lambda { |type| type.to_sym }
      )
    end
  end
end
