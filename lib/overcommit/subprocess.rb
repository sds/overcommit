require 'childprocess'
require 'tempfile'

module Overcommit
  # Manages execution of a child process, collecting the exit status and
  # standard out/error output.
  class Subprocess
    # Encapsulates the result of a process.
    Result = Struct.new(:status, :stderr, :stdout) do
      def success?
        status == 0
      end
    end

    # Spawns a new process using the given array of arguments (the first
    # element is the command).
    def self.spawn(args)
      process = ChildProcess.build(*args)

      err = ::Tempfile.new('err')
      err.sync = true
      out = ::Tempfile.new('out')
      out.sync = true

      process.io.stderr = err
      process.io.stdout = out

      process.start
      process.wait

      err.rewind
      out.rewind

      Result.new(process.exit_code, err.read, out.read)
    end
  end
end
