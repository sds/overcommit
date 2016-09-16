module Overcommit::Hook::PreCommit
  # Checks for line endings in files.
  class LineEndings < Base
    def run
      messages = []

      text_files.map do |file_name|
        file = File.open(file_name)
        file.each_line do |line|
          next if unix? && line =~ /\A((?!\r).)*\n\z/
          next if windows? && line =~ /\A.*\r\n\z/

          messages << Overcommit::Hook::Message.new(
            :error,
            file_name,
            file.lineno,
            "#{file_name}:#{file.lineno}:#{line.inspect}"
          )
        end
      end

      messages
    end

    private

    def text_files
      result = execute(%w[git grep -zIl \'\' --], args: applicable_files)
      raise 'Unable to access git tree' unless result.success?

      result.stdout.split("\0")
    end

    def unix?
      config['eol'] == 'lf'
    end

    def windows?
      config['eol'] == 'crlf'
    end
  end
end
