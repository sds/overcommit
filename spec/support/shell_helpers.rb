require 'overcommit/subprocess'

# Helpers for executing shell commands in tests.
module ShellHelpers
  def shell(command)
    Overcommit::Subprocess.spawn(command)
  end
end
