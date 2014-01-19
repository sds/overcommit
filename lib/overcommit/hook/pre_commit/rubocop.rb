module Overcommit::Hook::PreCommit
  # Runs `rubocop` against any modified Ruby files.
  class Rubocop < Base
    def run
      unless in_path?('rubocop')
        return :warn, 'Rubocop not installed -- run `gem install rubocop`'
      end

      result = command("rubocop --format=emacs #{applicable_files.join(' ')} 2>&1")
      return :good if result.success?

      # Keep lines from the output for files that we actually modified
      error_lines, warning_lines = result.stdout.split("\n").partition do |output_line|
        if match = output_line.match(/^([^:]+):(\d+)/)
          file = match[1]
          line = match[2]
        end
        modified_lines(file).include?(line.to_i)
      end

      return :bad, error_lines.join("\n") unless error_lines.empty?
      return :warn, "Modified files have lints (on lines you didn't modify)\n" <<
                    warning_lines.join("\n")
    end
  end
end
