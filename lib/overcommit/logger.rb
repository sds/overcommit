module Overcommit
  # Encapsulates all communication to an output source.
  class Logger
    # Helper for creating a logger which outputs nothing.
    def self.silent
      new(File.open('/dev/null', 'w'))
    end

    def initialize(out)
      @out = out
    end

    def partial(*args)
      @out.print(*args)
    end

    def log(*args)
      @out.puts(*args)
    end

    def bold(*args)
      color('1', *args)
    end

    def error(*args)
      color(31, *args)
    end

    def bold_error(*args)
      color('1;31', *args)
    end

    def success(*args)
      color(32, *args)
    end

    def warning(*args)
      color(33, *args)
    end

    def bold_warning(*args)
      color('1;33', *args)
    end

    private

    def color(code, str, partial = false)
      send(partial ? :partial : :log,
           @out.tty? ? "\033[#{code}m#{str}\033[0m" : str)
    end
  end
end
