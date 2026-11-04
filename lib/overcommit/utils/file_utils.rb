# frozen_string_literal: true

module Overcommit::Utils
  # Utility functions for file IO.
  module FileUtils
    class << self
      def symlink(old_name, new_name)
        File.symlink(old_name, new_name)
      end

      def symlink?(file_name)
        File.symlink?(file_name)
      end

      def readlink(link_name)
        File.readlink(link_name)
      end
    end
  end
end
