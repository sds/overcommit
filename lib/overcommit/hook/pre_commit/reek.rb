module Overcommit::Hook::PreCommit
  # Runs `reek` against any modified Ruby files.
  class Reek < Base
    def run
      result = execute(command + %w[--single-line --no-color] + applicable_files)
      return :pass if result.success?

      output = scrub_output(result.stdout + result.stderr)

      extract_messages(
        output,
        /^(?<file>[^:]+):(?<line>\d+):/,
      )
    end

    private

    def scrub_output(raw_output)
      raw_output.split("\n").grep(/^(.(?!warning))*$/)
    end
  end
end
