module Overcommit::Hook::PreCommit
  # Runs `jscs` (JavaScript Code Style Checker) against any modified JavaScript
  # files.
  class Jscs < Base
    def run
      unless in_path?('jscs')
        return :warn, 'jscs not installed -- run `npm install -g jscs`'
      end

      result = execute(%w[jscs --reporter=inline] + applicable_files)
      return :pass if result.success?

      if result.status == 1
        return :warn, result.stderr.chomp
      end

      # Keep lines from the output for files that we actually modified
      error_lines, warning_lines = result.stdout.split("\n").partition do |output_line|
        if match = output_line.match(/^([^:]+):[^\d]+(\d+)/)
          file = match[1]
          line = match[2]
        end
        modified_lines(file).include?(line.to_i)
      end

      return :fail, error_lines.join("\n") unless error_lines.empty?

      [:warn, "Modified files have lints (on lines you didn't modify)\n" <<
              warning_lines.join("\n")]
    end
  end
end
