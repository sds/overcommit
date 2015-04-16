require 'rbconfig'

module Overcommit
  # Methods relating to the current operating system
  module OS
    class << self
      def windows?
        (/mswin|msys|mingw|cygwin|bccwin|wince|emc/ =~ host_os) != nil
      end

      def mac?
        (/darwin|mac os/ =~ host_os) != nil
      end

      def unix?
        !windows?
      end

      def linux?
        unix? && !mac?
      end

      private

      def host_os
        @os ||= ::RbConfig::CONFIG['host_os']
      end
    end
  end
end
