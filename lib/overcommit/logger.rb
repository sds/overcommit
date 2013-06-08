require 'singleton'

# This class centralizes all communication to STDOUT
module Overcommit
  class Logger
    include Singleton

    attr_accessor :output

    def partial(*args)
      out.print *args
    end

    def log(*args)
      out.puts *args
    end

    def bold(str)
      color('1;37', str)
    end

    def error(str)
      color(31, str)
    end

    def success(str)
      color(32, str)
    end

    def warning(str)
      color(33, str)
    end

    def notice(str)
      color('1;33', str)
    end

    def out
      self.output ||= $stdout
    end

  private

    def color(code, str)
      log(out.isatty ? "\033[#{code}m#{str}\033[0m" : str)
    end
  end
end
