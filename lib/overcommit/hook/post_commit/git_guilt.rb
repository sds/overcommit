module Overcommit::Hook::PostCommit
  # Calculates the change in blame since the last revision.
  #
  # @see https://www.npmjs.com/package/git-guilt
  class GitGuilt < Base
    PLUS_MINUS_REGEX = /^(.*?)(?:(\++)|(-+))$/
    GREEN = 32
    RED = 31

    def run
      return :pass if initial_commit?
      result = execute(command)
      return :fail, result.stderr unless result.success?

      return :pass if result.stdout.strip.empty?

      output = []
      result.stdout.scan(PLUS_MINUS_REGEX) do |user, plus, minus|
        plus = color(GREEN, plus)
        minus = color(RED, minus)
        output << "#{user}#{plus}#{minus}"
      end

      [:warn, output.join("\n")]
    end

    private

    # Returns text wrapped in ANSI escape code necessary to produce a given
    # color/text display.
    #
    # Taken from Overcommit::Logger as a temporary workaround.
    # TODO: expose logger instance to hooks for colorized output
    #
    # @param code [String] ANSI escape code, e.g. '1;33' for "bold yellow"
    # @param str [String] string to wrap
    def color(code, str)
      STDOUT.tty? ? "\033[#{code}m#{str}\033[0m" : str
    end
  end
end
