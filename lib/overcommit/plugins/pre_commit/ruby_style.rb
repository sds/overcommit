module Overcommit::GitHook
  class RubyStyle < HookSpecificCheck
    include HookRegistry
    file_types :rb, :rake

    def run_check
      unless in_path?('rubocop')
        return :warn, 'rubocop not installed -- run `gem install rubocop`'
      end

      paths_to_staged_files = Hash[staged.map { |s| [s.path, s] }]

      output = run_rubocop
      return :good if $?.success?

      # Keep lines from the output for files that we actually modified
      error_lines, warning_lines = output.lines.partition do |output_line|
        if match = output_line.match(/^([^:]+):(\d+)/)
          file = match[1]
          line = match[2]
        end
        unless paths_to_staged_files[file]
          return :warn, "Unexpected output from rubocop:\n#{output}"
        end
        paths_to_staged_files[file].modified_lines.include?(line.to_i)
      end

      return :bad, error_lines.join unless error_lines.empty?
      return :warn, "Modified files have style lints (on lines you didn't modify)\n" <<
                    warning_lines.join
    end

    private

    def run_rubocop
      staged.reduce('') do |output, staged_file|
        config = detect_rubocop_yml_for(staged_file)
        config = config ? "-c #{config}" : ''
        output + `rubocop #{config} --format=emacs #{staged_file.path} 2>&1`
      end
    end

    def detect_rubocop_yml_for(staged_file)
      dir = staged_file.original_path.split('/')
      file = ''
      file = rubo_file(dir) while !File.exists?(file) && dir.pop
      file
    end

    def rubo_file(dir)
      File.join(*dir, '.rubocop.yml')
    end

  end
end
