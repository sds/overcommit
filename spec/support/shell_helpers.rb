require 'timeout'
require 'overcommit/subprocess'

# Helpers for executing shell commands in tests.
module ShellHelpers
  def shell(command)
    Overcommit::Subprocess.spawn(command)
  end

  def symlink(source, dest)
    Overcommit::Utils::FileUtils.symlink(source, dest)
  end

  def touch(file)
    FileUtils.touch(file)
  end

  # Wait until the specified condition is true or the given timeout has elapsed,
  # whichever comes first.
  #
  # @param options [Hash]
  # @raise [Timeout::TimeoutError] timeout has elapsed before condition holds
  def wait_until(options = {})
    Timeout.timeout(options.fetch(:timeout, 1)) do
      loop do
        return if yield
        sleep options.fetch(:check_interval, 0.1)
      end
    end
  end

  # Output text to file using `File#puts`, which mimics the behavior of the
  # `echo` shell command.
  #
  # @param text [String] text to write
  # @param file [String] path to target file
  # @param options [Hash]
  # @option options [Boolean] :append whether to append to existing file
  def echo(text, file, options = {})
    mode = options[:append] ? 'a' : 'w'
    File.open(file, mode) { |f| f.puts(text) }
  end
end
