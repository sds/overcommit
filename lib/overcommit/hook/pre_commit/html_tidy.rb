module Overcommit::Hook::PreCommit
  # Runs `tidy` against any modified HTML files.
  #
  # @see http://www.html-tidy.org/
  class HtmlTidy < Base
    MESSAGE_REGEX = /
      ^(?<file>(?:\w:)?[^:]+):\s
      line\s(?<line>\d+)\s
      column\s(?<col>\d+)\s-\s
      (?<type>Error|Warning):\s(?<message>.+)$
    /x

    def run
      # example message:
      #   line 4 column 24 - Warning: <html> proprietary attribute "class"
      applicable_files.collect do |file|
        result = execute(command + [file])
        output = result.stderr.chomp

        extract_messages(
          output.split("\n").collect { |msg| "#{file}: #{msg}" },
          MESSAGE_REGEX,
          lambda { |type| type.downcase.to_sym }
        )
      end.flatten
    end
  end
end
