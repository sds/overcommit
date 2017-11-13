module Overcommit::Hook::PreCommit
  # Runs `stylelint` against any modified CSS files.
  #
  # @see https://github.com/stylelint/stylelint
  class StyleLint < Base
    MESSAGE_REGEX = /(?<type>✖|⚠)/

    def run
      result = execute(command, args: applicable_files)
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
