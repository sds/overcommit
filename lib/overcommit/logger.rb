require 'singleton'

# This class centralizes all communication to STDOUT
module Overcommit
  class Logger
    include Singleton

    def partial(*args)
      print *args
    end

    def log(*args)
      puts *args
    end

    def bold(str)
      log "\033[1;37m#{str}\033[0m"
    end

    def error(str)
      log "\033[31m#{str}\033[0m"
    end

    def success(str)
      log "\033[32m#{str}\033[0m"
    end

    def warning(str)
      log "\033[33m#{str}\033[0m"
    end

    def notice(str)
      log "\033[1;33m#{str}\033[0m"
    end
  end
end
