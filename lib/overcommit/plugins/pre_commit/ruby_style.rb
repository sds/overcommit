require 'enumerator'
require 'pathname'

module Overcommit::GitHook
  class RubyStyle < HookSpecificCheck
    include HookRegistry
    file_types :rb, :rake

    def run_check
      unless in_path?('rubocop')
        return :warn, 'rubocop not installed -- run `gem install rubocop`'
      end

      paths_to_staged_files = Hash[staged.map { |s| [s.path, s] }]

      success, output = run_rubocop
      return :good if success

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
      success, output = true, ''
      rubocop_config_mapping.each do |config, files|
        config = config ? "-c #{config}" : ''
        output += `rubocop #{config} --format=emacs #{files.join(' ')} 2>&1`
        success = success && $?.success?
      end
      [success, output]
    end

    def rubocop_config_mapping
      staged.inject({}) do |mapping, file|
        config = rubocop_yml_for(file)
        mapping[config] ||= []
        mapping[config] << file.path
        mapping
      end
    end

    def rubocop_yml_for(staged_file)
      possible_files(staged_file.original_path).find { |path| path.file? }
    end

    def possible_files(file_path)
      files = Pathname.new(file_path).enum_for(:ascend).
                       map { |path| path + '.rubocop.yml' }
      files << Pathname.new('.rubocop.yml')
    end
  end
end
