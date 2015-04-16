require 'overcommit/os'
require 'overcommit/subprocess'

# Adapted from http://stackoverflow.com/a/22716582
class << File
  alias_method :old_symlink, :symlink
  alias_method :old_symlink?, :symlink?
  alias_method :old_readlink, :readlink

  def symlink(old_name, new_name)
    if Overcommit::OS.windows?
      result = Overcommit::Subprocess.spawn(
        ['cmd.exe', "/c mklink /J #{new_name} #{old_name}"]
      )
      result.status
    else
      old_symlink(old_name, new_name)
    end
  end

  def symlink?(file_name)
    if Overcommit::OS.windows?
      result = Overcommit::Subprocess.spawn(
        ['cmd.exe', "/c dir #{file_name} | find \"<JUNCTION>\""]
      )
      result.success?
    else
      old_symlink?(file_name)
    end
  end

  def readlink(link_name)
    if Overcommit::OS.windows?
      result = Overcommit::Subprocess.spawn(
        ['cmd.exe', "/c dir #{link_name} | find \"<JUNCTION>\""]
      )
      raise ArgumentError, "#{link_name} is not a symlink" unless result.success?

      # Extract symlink target from output, which looks like:
      #   11/13/2012 12:53 AM <SYMLINK> mysymlink [C:\Windows\Temp\somefile.txt]
      result.stdout[/\[.+\]/][1..-2]
    else
      old_readlink(link_name)
    end
  end
end
