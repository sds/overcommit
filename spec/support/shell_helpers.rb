require 'timeout'
require 'overcommit/subprocess'

# Helpers for executing shell commands in tests.
module ShellHelpers
  def shell(command)
    Overcommit::Subprocess.spawn(command)
  end

  # Wait until the specified condition is true or the given timeout has elapsed,
  # whichever comes first.
  #
  # @param options [Hash]
  # @raise [Timeout::TimeoutError] timeout has elapsed before condition holds
  def wait_until(options = {}, &block)
    Timeout.timeout(options.fetch(:timeout, 1)) do
      loop do
        return if block.call
        sleep options.fetch(:check_interval, 0.1)
      end
    end
  end
end
