module Overcommit::Hook::PreCommit
  # Runs `htmlhint` against any modified HTML files.
  #
  # @see http://htmlhint.com/
  class HtmlHint < Base
    def run
      result = execute(command + applicable_files)
      output = Overcommit::Utils.strip_color_codes(result.stdout.chomp)

      message_groups = output.split("\n\n")[0..-2]
      message_groups.map do |group|
        lines = group.split("\n").map(&:strip)
        file = lines[0][/(.+):/, 1]
        extract_messages(
          lines[1..-1].map { |msg| "#{file}: #{msg}" },
          /^(?<file>(?:\w:)?[^:]+): line (?<line>\d+)/
        )
      end.flatten
    end
  end
end
