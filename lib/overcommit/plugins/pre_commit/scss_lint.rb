module Overcommit::GitHook
  class ScssLint < HookSpecificCheck
    include HookRegistry
    file_type :scss

    def run_check
      begin
        require 'scss_lint'
      rescue LoadError
        return :warn, 'scss-lint not installed -- run `gem install scss-lint`'
      end

      paths_to_staged_files = Hash[staged.map { |s| [s.path, s] }]

      success, output = run_scss_lint
      return :good if success

      # Keep lines from the output for files that we actually modified
      error_lines, warning_lines = output.lines.partition do |output_line|
        if match = output_line.match(/^([^:]+):(\d+)/)
          file = match[1]
          line = match[2]
        end
        unless paths_to_staged_files[file]
          return :warn, "Unexpected output from scss-lint:\n#{output}"
        end
        paths_to_staged_files[file].modified_lines.include?(line.to_i)
      end

      return :bad, error_lines.join unless error_lines.empty?
      return :warn, "Modified files have lints (on lines you didn't modify)\n" <<
                    warning_lines.join
    end

  private

    def run_scss_lint
      success, output = true, ''
      scss_lint_config_mapping.each do |config, files|
        config = config ? "-c #{config}" : ''
        output += `scss-lint #{config} #{files.join(' ')} 2>&1`
        success = success && $?.success?
      end
      [success, output]
    end

    def scss_lint_config_mapping
      staged.inject({}) do |mapping, file|
        config = scss_lint_yml_for(file)
        mapping[config] ||= []
        mapping[config] << file.path
        mapping
      end
    end

    def scss_lint_yml_for(staged_file)
      possible_files(staged_file.original_path).find { |path| path.file? }
    end

    def possible_files(file_path)
      files = Pathname.new(file_path).enum_for(:ascend).
                       map { |path| path + '.scss-lint.yml' }
      files << Pathname.new('.scss-lint.yml')
    end
  end
end
