require 'overcommit/os'
require 'overcommit/subprocess'

module Overcommit::Utils
  # Utility functions for file IO.
  module FileUtils
    class << self
      # When the host OS is Windows, uses the `mklink` command to create an
      # NTFS symbolic link from `new_name` to `old_name`. Otherwise delegates
      # to `File.symlink`
      def symlink(old_name, new_name)
        return File.symlink(old_name, new_name) unless Overcommit::OS.windows?

        result = win32_mklink_cmd(old_name, new_name)
        result.status
      end

      # When the host OS is Windows, uses the `dir` command to check whether
      # `file_name` is an NTFS symbolic link. Otherwise delegates to
      # `File.symlink`.
      def symlink?(file_name)
        return File.symlink?(file_name) unless Overcommit::OS.windows?

        result = win32_dir_cmd(file_name)
        win32_symlink?(result.stdout)
      end

      # When the host OS is Windows, uses the `dir` command to check whether
      # `link_name` is an NTFS symbolic link. If so, it parses the target from
      # the command output. Otherwise raises an `ArgumentError`. Delegates to
      # `File.readlink` if the host OS is not Windows.
      def readlink(link_name)
        return File.readlink(link_name) unless Overcommit::OS.windows?

        result = win32_dir_cmd(link_name)

        unless win32_symlink?(result.stdout)
          raise ArgumentError, "#{link_name} is not a symlink"
        end

        # Extract symlink target from output, which looks like:
        #   11/13/2012 12:53 AM <SYMLINK> mysymlink [C:\Windows\Temp\somefile.txt]
        result.stdout[/\[(.+)\]/, 1]
      end

      private

      def win32_dir_cmd(file_name)
        Overcommit::Subprocess.spawn(
          %W[dir #{win32_fix_pathsep(file_name)}]
        )
      end

      def win32_mklink_cmd(old_name, new_name)
        Overcommit::Subprocess.spawn(
          %W[mklink #{win32_fix_pathsep(new_name)} #{win32_fix_pathsep(old_name)}]
        )
      end

      def win32_fix_pathsep(path)
        path.tr(File::SEPARATOR, Overcommit::OS::SEPARATOR)
      end

      def win32_symlink?(dir_output)
        !(dir_output =~ /<SYMLINK>/).nil?
      end
    end
  end
end
