module Overcommit::Hook::PreCommit
  # Runs `csslint` against any modified CSS files.
  #
  # @see https://github.com/CSSLint/csslint
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
        output.split("\n").reject(&:empty?),
        MESSAGE_REGEX,
        lambda { |type| type.downcase.to_sym }
      )
    end
  end
end
