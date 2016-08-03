module Overcommit::Hook::PreCommit
  # Checks for line endings in files.
  class LineEndings < Base
    def run
      messages = []

      applicable_files.map do |file_name|
        file = File.open(file_name)
        file.each_line do |line|
          next if unix? && !line.end_with?("\r\n")
          next if windows? && line.end_with?("\r\n")

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

    def unix?
      config['representation'] == 'unix'
    end

    def windows?
      config['representation'] == 'windows'
    end
  end
end
