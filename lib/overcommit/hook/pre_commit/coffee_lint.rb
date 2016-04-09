module Overcommit::Hook::PreCommit
  # Runs `coffeelint` against any modified CoffeeScript files.
  #
  # @see http://www.coffeelint.org/
  class CoffeeLint < Base
    MESSAGE_REGEX = /
      ^(?<file>.+)
      ,(?<line>\d*),\d*
      ,(?<type>\w+)
      ,(?<msg>.+)$
    /x

    MESSAGE_TYPE_CATEGORIZER = lambda do |type|
      type.include?('w') ? :warning : :error
    end

    def run
      result = execute(command, args: applicable_files)
      parse_messages(result.stdout)
    end

    private

    def parse_messages(output)
      output.scan(MESSAGE_REGEX).map do |file, line, type, msg|
        line = line.to_i
        type = MESSAGE_TYPE_CATEGORIZER.call(type)
        text = "#{file}:#{line}:#{type} #{msg}"
        Overcommit::Hook::Message.new(type, file, line, text)
      end
    end
  end
end
