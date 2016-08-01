module Overcommit::Hook::PreCommit
  # Runs `credo` against any modified ex files.
  #
  # @see https://github.com/rrrene/credo
  class Credo < Base
    # example message:
    # lib/file1.ex:1:11: R: Modules should have a @moduledoc tag.
    # lib/file2.ex:12:81: R: Line is too long (max is 80, was 81).

    def run
      result = execute command
      return :pass if result.success?

      result.stdout.split("\n").map(&:strip).reject(&:empty?).
        map { |error| message(error) }
    end

    private

    def message(error)
      file, line = error.split(':')
      Overcommit::Hook::Message.new(:error, file, Integer(line), error)
    end
  end
end
