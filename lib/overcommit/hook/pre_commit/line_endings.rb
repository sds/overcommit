module Overcommit::Hook::PreCommit
  # Checks for line endings in files.
  #
  # WARNING: Works with Git 2.10.0 or newer.
  class LineEndings < Base
    def run
      messages = []

      offending_files.map do |file_name|
        file = File.open(file_name)
        file.each_line do |line|
          # remove configured line-ending
          line.gsub!(/#{config['eol']}/, '')

          # detect any left over line-ending characters
          next unless line.end_with?("\n", "\r")

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

    def offending_files
      result = execute(%w[git ls-files --eol -z --], args: applicable_files)
      raise 'Unable to access git tree' unless result.success?

      result.stdout.split("\0").map do |file_info|
        i, _w, _attr, path = file_info.split
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
