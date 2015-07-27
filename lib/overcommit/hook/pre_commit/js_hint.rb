module Overcommit::Hook::PreCommit
  # Runs `jshint` against any modified JavaScript files.
  #
  # @see http://jshint.com/
  class JsHint < Base
    def run
      result = execute(command, args: applicable_files)
      output = result.stdout.chomp

      return :pass if result.success? && output.empty?

      # example message:
      #   path/to/file.js: line 1, col 0, Error message (E001)
      extract_messages(
        output.split("\n").grep(/E|W/),
        /^(?<file>(?:\w:)?[^:]+):[^\d]+(?<line>\d+).+\((?<type>E|W)\d+\)/,
        lambda { |type| type.include?('W') ? :warning : :error }
      )
    end
  end
end
