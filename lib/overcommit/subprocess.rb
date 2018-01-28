require 'childprocess'
require 'tempfile'

module Overcommit
  # Manages execution of a child process, collecting the exit status and
  # standard out/error output.
  class Subprocess
    # Encapsulates the result of a process.
    #
    # @attr_reader status [Integer] exit status code returned by process
    # @attr_reader stdout [String] standard output stream output
    # @attr_reader stderr [String] standard error stream output
    Result = Struct.new(:status, :stdout, :stderr) do
      def success?
        status == 0
      end
    end

    class << self
      # Spawns a new process using the given array of arguments (the first
      # element is the command).
      #
      # @param args [Array<String>]
      # @param options [Hash]
      # @option options [String] input string to pass via standard input stream
      # @return [Result]
      def spawn(args, options = {})
        args = win32_prepare_args(args) if OS.windows?

        process = ChildProcess.build(*args)

        out, err = assign_output_streams(process)

        process.duplex = true if options[:input] # Make stdin available if needed
        process.start
        if options[:input]
          begin
            process.io.stdin.puts(options[:input])
          rescue StandardError # rubocop:disable Lint/HandleExceptions
            # Silently ignore if the standard input stream of the spawned
            # process is closed before we get a chance to write to it. This
            # happens on JRuby a lot.
          ensure
            process.io.stdin.close
          end
        end
        process.wait

        err.rewind
        out.rewind

        Result.new(process.exit_code, out.read, err.read)
      end

      # Spawns a new process in the background using the given array of
      # arguments (the first element is the command).
      def spawn_detached(args)
        args = win32_prepare_args(args) if OS.windows?

        process = ChildProcess.build(*args)
        process.detach = true

        assign_output_streams(process)

        process.start
      end

      private

      # Necessary to run commands in the cmd.exe context.
      # Args are joined to properly handle quotes and special characters.
      def win32_prepare_args(args)
        args = args.map do |arg|
          # Quote args that contain whitespace
          arg = "\"#{arg}\"" if arg =~ /\s/

          # Escape cmd.exe metacharacters
          arg.gsub(/[()%!^"<>&|]/, '^\0')
        end

        %w[cmd.exe /c] + [args.join(' ')]
      end

      # @param process [ChildProcess]
      # @return [Array<IO>]
      def assign_output_streams(process)
        %w[out err].map do |stream_name|
          ::Tempfile.new(stream_name).tap do |stream|
            stream.sync = true
            process.io.send("std#{stream_name}=", stream)
          end
        end
      end
    end
  end
end
