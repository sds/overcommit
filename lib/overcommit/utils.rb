module Overcommit
  module Utils
    class << self
      include ConsoleMethods

      @@hooks = []

      def register_hook(hook)
        @@hooks << hook
      end

      def run_hooks(*args)
        @@hooks.each { |hook| hook.new.run(*args) }
      end

      def hook_name
        File.basename($0).tr('-', '_')
      end

      def load_hooks
        require File.expand_path("../hooks/#{hook_name}", __FILE__)
      rescue LoadError
        error "No hook definition found for #{hook_name}"
        exit 1
      end

      def script_path(script)
        File.join(File.expand_path('../../hooks/scripts', $0), script)
      end

      # Shamelessly stolen from:
      # http://stackoverflow.com/questions/1509915/converting-camel-case-to-underscore-case-in-ruby
      def underscorize(str)
        str.gsub(/::/, '/').
            gsub(/([A-Z]+)([A-Z][a-z])/, '\1_\2').
            gsub(/([a-z\d])([A-Z])/, '\1_\2').
            tr('-', '_').
            downcase
      end

      # Get a list of staged Added, Copied, or Modified files (ignore renames
      # and deletions, since there should be nothing to check).
      def modified_files
        @modified_files ||=
          `git diff --cached --name-only --diff-filter=ACM`.split "\n"
      end
    end
  end
end
