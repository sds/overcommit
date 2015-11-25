module Overcommit::Hook::PreCommit
  # Runs `dogma` against any modified ex files.
  #
  # @see https://github.com/lpil/dogma
  class Dogma < Base
    def run
      result = execute command
      return :pass if result.success?

      messages = []
      # example message:
      #  == web/channels/user_socket.ex ==
      #  26: LineLength: Line length should not exceed 80 chars (was 83).
      #  1: ModuleDoc: Module Sample.UserSocket is missing a @moduledoc.
      output = result.stdout.chomp.match(/(==.+)/m)

      if output
        output.captures.first.split(/\n\n/).each do |error_group|
          errors = error_group.split /\n/
          file = errors.shift.gsub /[ =]/, ''
          errors.each do |error|
            line = error.split(': ').first
            messages << Overcommit::Hook::Message.new(:error, file, line, "#{file}: #{error}")
          end
        end
      end

      messages
    end
  end
end
