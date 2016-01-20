require 'rbconfig'

module Overcommit
  # Methods relating to the current operating system
  module OS
    class << self
      def windows?
        !(/mswin|msys|mingw|bccwin|wince|emc/ =~ host_os).nil?
      end

      def cygwin?
        !(/cygwin/ =~ host_os).nil?
      end

      def mac?
        !(/darwin|mac os/ =~ host_os).nil?
      end

      def unix?
        !windows?
      end

      def linux?
        unix? && !mac? && !cygwin?
      end

      private

      def host_os
        @os ||= ::RbConfig::CONFIG['host_os'].freeze
      end
    end

    SEPARATOR = (windows? ? '\\' : File::SEPARATOR).freeze
  end
end
