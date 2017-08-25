module Overcommit
  # Encapsulates all communication to an output source.
  class Logger
    # Helper for creating a logger which outputs nothing.
    def self.silent
      new(File.open(File::NULL, 'w'))
    end

    # Creates a logger that will write to the given output stream.
    #
    # @param out [IO]
    def initialize(out)
      @out = out
      @colorize =
        if ENV.key?('OVERCOMMIT_COLOR')
          !%w[0 false no].include?(ENV['OVERCOMMIT_COLOR'])
        else
          @out.tty?
        end
    end

    # Write output without a trailing newline.
    def partial(*args)
      @out.print(*args)
    end

    # Prints a newline character (alias for readability).
    def newline
      log
    end

    # Write a line of output.
    #
    # A newline character will always be appended.
    def log(*args)
      @out.puts(*args)
    end

    # Write a line of output if debug mode is enabled.
    def debug(*args)
      color('35', *args) unless ENV.fetch('OVERCOMMIT_DEBUG', '').empty?
    end

    # Write a line of output that is intended to be emphasized.
    def bold(*args)
      color('1', *args)
    end

    # Write a line of output indicating a problem or error.
    def error(*args)
      color(31, *args)
    end

    # Write a line of output indicating a problem or error which is emphasized
    # over a regular problem or error.
    def bold_error(*args)
      color('1;31', *args)
    end

    # Write a line of output indicating a successful or noteworthy event.
    def success(*args)
      color(32, *args)
    end

    # Write a line of output indicating a potential cause for concern, but not
    # an actual error.
    def warning(*args)
      color(33, *args)
    end

    # Write a line of output indicating a potential cause for concern, but with
    # greater emphasize compared to other warnings.
    def bold_warning(*args)
      color('1;33', *args)
    end

    private

    # Outputs text wrapped in ANSI escape code necessary to produce a given
    # color/text display.
    #
    # @param code [String] ANSI escape code, e.g. '1;33' for "bold yellow"
    # @param str [String] string to wrap
    # @param partial [true,false] whether to omit a newline
    def color(code, str, partial = false)
      send(partial ? :partial : :log,
           @colorize ? "\033[#{code}m#{str}\033[0m" : str)
    end
  end
end
