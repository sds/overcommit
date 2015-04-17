require 'overcommit/os'
require 'overcommit/subprocess'

# Adapted from http://stackoverflow.com/a/22716582
class << File
  alias_method :old_symlink, :symlink
  alias_method :old_symlink?, :symlink?
  alias_method :old_readlink, :readlink

  def symlink(old_name, new_name)
    return old_symlink(old_name, new_name) unless Overcommit::OS.windows?

    result = win32_mklink_cmd(old_name, new_name)
    result.status
  end

  def symlink?(file_name)
    return old_symlink?(file_name) unless Overcommit::OS.windows?

    result = win32_dir_cmd(file_name)
    !(result.stdout =~ /<SYMLINK>/).nil?
  end

  def readlink(link_name)
    return old_readlink(link_name) unless Overcommit::OS.windows?

    result = win32_dir_cmd(link_name)

    unless result.stdout =~ /<SYMLINK>/
      raise ArgumentError, "#{link_name} is not a symlink"
    end

    # Extract symlink target from output, which looks like:
    #   11/13/2012 12:53 AM <SYMLINK> mysymlink [C:\Windows\Temp\somefile.txt]
    result.stdout[/\[.+\]/][1..-2]
  end

  private

  def win32_dir_cmd(file_name)
    Overcommit::Subprocess.spawn(
      %W[cmd.exe /c dir #{win32_fix_pathsep(file_name)}]
    )
  end

  def win32_mklink_cmd(old_name, new_name)
    Overcommit::Subprocess.spawn(
      %W[cmd.exe /c mklink #{win32_fix_pathsep(new_name)} #{win32_fix_pathsep(old_name)}]
    )
  end

  def win32_fix_pathsep(path)
    path.gsub('/', '\\')
  end
end
