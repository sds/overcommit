module Overcommit::Hook::PreCommit
  # Checks for line endings in files.
  #
  # WARNING: Works with Git 2.10.0 or newer.
  class LineEndings < Base
    def run
      messages = []

      offending_files.map do |file_name|
        file = File.open(file_name)
        begin
          messages += check_file(file, file_name)
        rescue ArgumentError => ex
          # File is likely a binary file which this check should ignore, but
          # print a warning just in case
          messages << Overcommit::Hook::Message.new(
            :warning,
            file_name,
            file.lineno,
            "#{file_name}:#{file.lineno}:#{ex.message}"
          )
        end
      end

      messages
    end

    private

    def check_file(file, file_name)
      messages_for_file = []

      file.each_line do |line|
        # Remove configured line-ending
        line.gsub!(/#{config['eol']}/, '')

        # Detect any left over line-ending characters
        next unless line.end_with?("\n", "\r")

        messages_for_file << Overcommit::Hook::Message.new(
          :error,
          file_name,
          file.lineno,
          "#{file_name}:#{file.lineno}:#{line.inspect}"
        )
      end

      messages_for_file
    end

    def offending_files
      result = execute(%w[git ls-files --eol -z --], args: applicable_files)
      raise 'Unable to access git tree' unless result.success?

      result.stdout.split("\0").map do |file_info|
        info, path = file_info.split("\t")
        i = info.split.first
        next if i == 'l/-text' # ignore binary files
        next if i == "l/#{eol}"
        path
      end.compact
    end

    def eol
      @eol ||=  case config['eol']
                when "\n"
                  'lf'
                when "\r\n"
                  'crlf'
                else
                  raise 'Invalid `eol` option specified: must be "\n" or "\r\n"'
                end
    end
  end
end
