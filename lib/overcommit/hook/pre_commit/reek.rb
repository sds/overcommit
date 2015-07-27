module Overcommit::Hook::PreCommit
  # Runs `reek` against any modified Ruby files.
  #
  # @see https://github.com/troessner/reek
  class Reek < Base
    def run
      result = execute(command, args: applicable_files)
      return :pass if result.success?

      output = scrub_output(result.stdout + result.stderr)

      extract_messages(
        output,
        /^\s*(?<file>(?:\w:)?[^:]+):(?<line>\d+):/,
      )
    end

    private

    def scrub_output(raw_output)
      raw_output.split("\n").grep(/^(.(?!warning))*$/)
    end
  end
end
