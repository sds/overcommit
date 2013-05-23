module Overcommit
  module ConsoleMethods
    def bold(str)
      puts "\033[1;37m#{str}\033[0m"
    end

    def error(str)
      puts "\033[31m#{str}\033[0m"
    end

    def success(str)
      puts "\033[32m#{str}\033[0m"
    end

    def warning(str)
      puts "\033[33m#{str}\033[0m"
    end

    def notice(str)
      puts "\033[1;33m#{str}\033[0m"
    end
  end
end
