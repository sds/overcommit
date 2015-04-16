require 'open3'

# Adapted from http://stackoverflow.com/a/22716582
class << File
  alias_method :old_symlink, :symlink
  alias_method :old_symlink?, :symlink?

  def symlink(old_name, new_name)
    # if on windows, call mklink, else self.symlink
    if Overcommit::OS.windows?
      _stdin, _stdout, _stderr, wait_thr =
        Open3.popen3('cmd.exe', "/c mklink #{new_name} #{old_name}")
      wait_thr.value.exitstatus
    else
      old_symlink(old_name, new_name)
    end
  end

  def symlink?(file_name)
    # if on windows, call mklink, else self.symlink
    if Overcommit::OS.windows?
      _stdin, _stdout, _stderr, wait_thr =
        Open3.popen3("cmd.exe /c dir #{file_name} | find \"SYMLINK\"")
      wait_thr.value.exitstatus
    else
      old_symlink?(file_name)
    end
  end
end
