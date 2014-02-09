require 'wopen3'

# Helpers for executing shell commands in tests.
module ShellHelpers
  def shell(command)
    Wopen3.system(command)
  end
end
