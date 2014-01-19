module Overcommit
  # Utility functions for general use.
  module Utils
    class << self
      def script_path(script)
        File.join(OVERCOMMIT_HOME, 'libexec', 'scripts', script)
      end

      # Returns an absolute path to the root of the repository.
      def repo_root
        @repo_root ||=
          begin
            result = `git rev-parse --show-toplevel`.chomp
            result if $?.success?
          end
      end

      # Shamelessly stolen from:
      # stackoverflow.com/questions/1509915/converting-camel-case-to-underscore-case-in-ruby
      def underscorize(str)
        str.gsub(/::/, '/').
            gsub(/([A-Z]+)([A-Z][a-z])/, '\1_\2').
            gsub(/([a-z\d])([A-Z])/, '\1_\2').
            tr('-', '_').
            downcase
      end
    end
  end
end
