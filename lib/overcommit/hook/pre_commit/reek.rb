module Overcommit::Hook::PreCommit
  # Runs `reek` against any modified Ruby files.
  class Reek < Base
    def run
      result = execute(%W[#{executable} --single-line --no-color] + applicable_files)
      return :pass if result.success?

      output = cleanup_output(result.stdout + result.stderr)

      # Keep lines from the output for files that we actually modified
      error_lines, warning_lines = output.partition do |output_line|
        if (match = output_line.match(/^([^:]+):(\d+)/))
          file = match[1]
          line = match[2]
        end
        modified_lines(file).include?(line.to_i)
      end

      return :fail, error_lines.join("\n") unless error_lines.empty?

      [:warn, "Modified files have lints (on lines you didn't modify)\n" <<
          warning_lines.join("\n")]
    end

    def cleanup_output(raw_output)
      raw_output.split("\n").grep(/^(.(?!warning))*$/)
    end
  end
end
