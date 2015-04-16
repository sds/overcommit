require 'overcommit/os'
require 'overcommit/subprocess'

# Adapted from http://stackoverflow.com/a/22716582
class << File
  alias_method :old_symlink, :symlink
  alias_method :old_symlink?, :symlink?

  def symlink(old_name, new_name)
    if Overcommit::OS.windows?
      result = Overcommit::Subprocess.spawn('cmd.exe', "/c mklink #{new_name} #{old_name}")
      result.status
    else
      old_symlink(old_name, new_name)
    end
  end

  def symlink?(file_name)
    if Overcommit::OS.windows?
      result = Overcommit::Subprocess.spawn('cmd.exe', "/c dir #{file_name} | find \"SYMLINK\"")
      result.success?
    else
      old_symlink?(file_name)
    end
  end
end
