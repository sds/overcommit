module Overcommit::GitHook
  class HamlStyle < HookSpecificCheck
    include HookRegistry
    file_types :haml

    def run_check
      unless in_path?('haml-lint')
        return :warn, 'haml-lint not installed -- run `gem install haml-lint`'
      end

      paths_to_staged_files = Hash[staged.map { |s| [s.path, s] }]
      staged_files = paths_to_staged_files.keys

      output = `haml-lint #{staged_files.join(' ')} 2>&1`
      return :good if $?.success?

      # Keep lines from the output for files that we actually modified
      error_lines, warning_lines = output.lines.partition do |output_line|
        if match = output_line.match(/^([^:]+):(\d+)/)
          file = match[1]
          line = match[2]
        end
        unless paths_to_staged_files[file]
          return :warn, "Unexpected output from haml-lint:\n#{output}"
        end
        paths_to_staged_files[file].modified_lines.include?(line.to_i)
      end

      return :bad, error_lines.join unless error_lines.empty?
      return :warn, "Modified files have lints (on lines you didn't modify)\n" <<
                    warning_lines.join
    end
  end
end
