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

    def bold(str)
      color('1', str)
    end

    def error(str)
      color(31, str)
    end

    def bold_error(str)
      color('1;31', str)
    end

    def success(str)
      color(32, str)
    end

    def warning(str)
      color(33, str)
    end

    def bold_warning(str)
      color('1;33', str)
    end

  private

    def color(code, str)
      log(@out.tty? ? "\033[#{code}m#{str}\033[0m" : str)
    end
  end
end
