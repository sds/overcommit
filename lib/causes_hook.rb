module Causes
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

  module GitHook
    include ConsoleMethods
    @@extensions = []

    def self.included(base)
      @@extensions << base
    end

    def self.run_hooks
      @@extensions.each { |ext| ext.new.run }
    end
  end

  class << self
    include ConsoleMethods

    def hook_name
      File.basename($0).gsub('-', '_')
    end

    def load_hooks
      require File.expand_path("../base/#{hook_name}", __FILE__)
    rescue LoadError => e
      error "No hook definition found for #{hook_name}"
      exit 1
    end
  end
end
