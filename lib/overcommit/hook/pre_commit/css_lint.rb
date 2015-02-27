module Overcommit::Hook::PreCommit
  # Runs `csslint` against any modified CSS files.
  class CssLint < Base
    MESSAGE_REGEX = /
      ^(?<file>[^:]+):\s
      (?:line\s(?<line>\d+)[^EW]+)?
      (?<type>Error|Warning)
    /x

    def run
      result = execute(command + applicable_files)
      output = result.stdout.chomp
      return :pass if result.success? && output.empty?

      extract_messages(
        output.split("\n").collect(&method(:add_line_number)),
        MESSAGE_REGEX,
        lambda { |type| type.downcase.to_sym }
      )
    end

    private

    # Hack to include messages that apply to the entire file
    def add_line_number(message)
      message.sub(/(?<!\d,\s)(Error|Warning)/, 'line 0, \1')
    end
  end
end
