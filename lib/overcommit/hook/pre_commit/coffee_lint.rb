require 'json'

module Overcommit::Hook::PreCommit
  # Runs `coffeelint` against any modified CoffeeScript files.
  class CoffeeLint < Base
    def run
      result = execute(command + applicable_files)

      begin
        parse_json_messages(result.stdout)
      rescue JSON::ParserError => e
        [:fail, "Error parsing coffeelint output: #{e.message}"]
      end
    end

    private

    def parse_json_messages(output)
      JSON.parse(output).collect do |file, messages|
        messages.collect { |msg| extract_message(file, msg) }
      end.flatten
    end

    def extract_message(file, message_hash)
      type = message_hash['level'].include?('w') ? :warning : :error
      line = message_hash['lineNumber']
      rule = message_hash['rule']
      msg = message_hash['message']
      text =
        if rule == 'coffeescript_error'
          # Syntax errors are output in different format.
          # Splice in the file name and grab the first line.
          msg.sub('[stdin]', file).split("\n")[0]
        else
          "#{file}:#{line}: #{msg} (#{rule})"
        end
      Overcommit::Hook::Message.new(type, file, line, text)
    end
  end
end
