module Overcommit
  # Distributes a list of arguments over multiple invocations of a command.
  #
  # This accomplishes the same functionality provided by `xargs` but in a
  # cross-platform way that does not require any pre-existing tools.
  #
  # One of the tradeoffs with this approach is that we no longer deal with a
  # single exit status from a command, but multiple (one for each invocation).
  #
  # This will return a struct similar to `Subprocess::Result` but with
  # additional `statuses`, `stdouts`, and `stderrs` fields so hook authors can
  # actually see the results of each invocation. If they don't care, the
  # standard `status`, `stdout`, and `stderr` will still work but be a
  # aggregation/concatenation of all statuses/outputs.
  class CommandSplitter
    # Encapsulates the result of a split argument run.
    #
    # @attr_reader statuses [Array<Integer>] status codes for invocations
    # @attr_reader stdouts [Array<String>] standard outputs from invocations
    # @attr_reader stderrs [Array<String>] standard error outputs from invocations
    Result = Struct.new(:statuses, :stdouts, :stderrs) do
      # Returns whether all invocations were successful.
      #
      # @return [true,false]
      def success?
        status == 0
      end

      # Returns `0` if all invocations returned `0`; `1` otherwise.
      #
      # @return [true,false]
      def status
        statuses.all? { |code| code == 0 } ? 0 : 1
      end

      # Returns concatenated standard output streams of all invocations in the
      # order they were executed.
      #
      # @return [String]
      def stdout
        stdouts.join
      end

      # Returns concatenated standard error streams of all invocations in the
      # order they were executed.
      #
      # @return [String]
      def stderr
        stderrs.join
      end
    end

    class << self
      def execute(initial_args, options)
        options = options.dup

        if (splittable_args = (options.delete(:args) { [] })).empty?
          raise Overcommit::Exceptions::InvalidCommandArgs,
                'Must specify list of arguments to split on'
        end

        # Execute each chunk of arguments in serial. We don't parallelize (yet)
        # since in theory we want to support parallelization at the hook level
        # and not within individual hooks.
        results = extract_argument_lists(initial_args, splittable_args).map do |arg_list|
          Overcommit::Subprocess.spawn(arg_list, options)
        end

        Result.new(results.map(&:status), results.map(&:stdout), results.map(&:stderr))
      end

      private

      # Given a list of prefix arguments and suffix arguments that can be split,
      # returns a list of argument lists that are executable on the current OS
      # without exceeding command line limitations.
      def extract_argument_lists(args, splittable_args)
        # Total number of bytes needed to contain the prefix command
        # (including byte separators between each argument)
        prefix_bytes = (args.size - 1) + args.reduce(0) { |sum, arg| sum + arg.bytesize }

        if prefix_bytes >= max_command_length
          raise Overcommit::Exceptions::InvalidCommandArgs,
                "Command `#{args.take(5).join(' ')} ...` is longer than the " \
                'maximum number of bytes allowed by the operating system ' \
                "(#{max_command_length})"
        end

        arg_lists = []
        index = 0
        while index <= splittable_args.length - 1
          arg_list, index = arguments_under_limit(splittable_args,
                                                  index,
                                                  max_command_length - prefix_bytes)
          arg_lists << args + arg_list
        end

        arg_lists
      end

      # @return [Array<Array<String>, Integer>] tuple of arguments and new index
      def arguments_under_limit(splittable_args, start_index, byte_limit)
        index = start_index
        total_bytes = 0

        loop do
          break if index > splittable_args.length - 1
          total_bytes += splittable_args[index].bytesize
          break if total_bytes > byte_limit # Not enough room
          index += 1
        end

        if index == start_index
          # No argument was consumed; perhaps a really long argument?
          raise Overcommit::Exceptions::InvalidCommandArgs,
                "Argument `#{splittable_args[index][0..5]}...` exceeds the " \
                'maximum command length when appended to command prefix and ' \
                "can't be split further"
        end

        [splittable_args[start_index...index], index]
      end

      # Returns the maximum number of arguments allowed in a single command on
      # this system.
      #
      # @return [Integer]
      def max_command_length
        @max_command_length ||=
          if Gem.win_platform?
            # Windows is limited to 2048 since that is a worst-case scenario.
            # http://blogs.msdn.com/b/oldnewthing/archive/2003/12/10/56028.aspx
            2048
          else
            # We fudge factor this by halving the buffer size since *nix systems
            # usually have pretty large limits, and the actual limit changes
            # depending on how much of your stack is environment variables.
            # Definitely erring on the side of overly cautious.
            `getconf ARG_MAX`.to_i / 2
          end
      end
    end
  end
end
