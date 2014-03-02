module Overcommit::Hook::PreCommit
  class LineLength < Base
    def run
      error_lines = []
      warning_lines = []
      max_line_length = @config['max']

      applicable_files.each do |file|
        File.open(file, 'r').read.split("\n").each_with_index do |line, index|
          if line.length > max_line_length
            message = format("#{file}:#{index + 1}: Line is too long [%d/%d]",
              line.length, max_line_length)

            if modified_lines(file).include?(index + 1)
              error_lines << message
            else
              warning_lines << message
            end
          end
        end
      end

      return :bad, error_lines.join("\n") if error_lines.any?
      return :warn, "Modified files have lints (on lines you didn't modify)\n" <<
                    warning_lines.join("\n") if warning_lines.any?
      :good
    end
  end
end
