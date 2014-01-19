module Overcommit::Hook::PreCommit
  # Runs `haml-lint` against any modified HAML files.
  class HamlLint < Base
    def run
      unless in_path?('haml-lint')
        return :warn, 'haml-lint not installed -- run `gem install haml-lint`'
      end

      result = command("haml-lint #{applicable_files.join(' ')}")
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
