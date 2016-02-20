require 'forwardable'
require 'overcommit/message_processor'

# Container for top-level hook-related classes and constants.
module Overcommit::Hook
  # Helper containing metadata about error/warning messages returned by hooks.
  Message = Struct.new(:type, :file, :line, :content) do
    def to_s
      content
    end
  end

  # Possible types of messages.
  MESSAGE_TYPES = [:error, :warning].freeze

  # Functionality common to all hooks.
  class Base # rubocop:disable Metrics/ClassLength
    extend Forwardable

    def_delegators :@context, :all_files, :modified_files
    attr_reader :config

    # @param config [Overcommit::Configuration]
    # @param context [Overcommit::HookContext]
    def initialize(config, context)
      @config = config.for_hook(self)
      @context = context
    end

    # Runs the hook.
    def run
      raise NotImplementedError, 'Hook must define `run`'
    end

    # Runs the hook and transforms the status returned based on the hook's
    # configuration.
    #
    # Poorly named because we already have a bunch of hooks in the wild that
    # implement `#run`, and we needed a wrapper step to transform the status
    # based on any custom configuration.
    def run_and_transform
      if output = check_for_requirements
        status = :fail
      else
        result = Overcommit::Utils.with_environment(@config.fetch('env', {})) { run }
        status, output = process_hook_return_value(result)
      end

      [transform_status(status), output]
    end

    def name
      self.class.name.split('::').last
    end

    def description
      @config['description'] || "Run #{name}"
    end

    def required?
      @config['required']
    end

    def parallelize?
      @config['parallelize'] != false
    end

    def processors
      @config.fetch('processors', 1)
    end

    def quiet?
      @config['quiet']
    end

    def enabled?
      @config['enabled'] != false
    end

    def skip?
      @config['skip']
    end

    def run?
      enabled? &&
        !(@config['requires_files'] && applicable_files.empty?)
    end

    def in_path?(cmd)
      Overcommit::Utils.in_path?(cmd)
    end

    # Execute a command in a separate process.
    #
    # If `splittable_args` is specified, ensures that those arguments are
    # concatenated onto the end of the `cmd` arguments, but split up so that the
    # operating system's maximum command length is not exceeded. This is useful
    # for splitting up long file lists.
    #
    # @param cmd [Array<String>] command arguments
    # @param options [Hash]
    # @option options [Array<String>] :args arguments that can be split up over
    #   multiple invocations (usually a list of files)
    # @option options [String] :input string to pass to process' standard input
    #   stream
    # @return [#status,#stdout,#stderr] struct containing result of invocation
    def execute(cmd, options = {})
      Overcommit::Utils.execute(cmd, options)
    end

    def execute_in_background(cmd)
      Overcommit::Utils.execute_in_background(cmd)
    end

    def required_executable
      @config['required_executable']
    end

    def required_libraries
      Array(@config['required_library'] || @config['required_libraries'])
    end

    # Return command to execute for this hook.
    #
    # This is intended to be configurable so hooks can prefix their commands
    # with `bundle exec` or similar. It will appends the command line flags
    # specified by the `flags` option after.
    #
    # Note that any files intended to be passed must be handled by the hook
    # itself.
    #
    # @return [Array<String>]
    def command
      Array(@config['command'] || required_executable) + flags
    end

    # Return command line flags to be passed to the command.
    #
    # This excludes the list of files, as that must be handled by the hook
    # itself.
    #
    # The intention here is to provide flexibility for when a tool
    # removes/renames its flags. Rather than wait for Overcommit to update the
    # flags it uses, you can update your configuration to use the new flags
    # right away without being blocked.
    #
    # Also note that any flags containing dynamic content must be passed in the
    # hook's {#run} method.
    #
    # @return [Array<String>]
    def flags
      Array(@config['flags'])
    end

    # Gets a list of staged files that apply to this hook based on its
    # configured `include` and `exclude` lists.
    def applicable_files
      @applicable_files ||= select_applicable(modified_files)
    end

    # Gets a list of all files that apply to this hook based on its
    # configured `include` and `exclude` lists.
    def included_files
      @included_files ||= select_applicable(all_files)
    end

    private

    def select_applicable(list)
      list.select { |file| applicable_file?(file) }.sort
    end

    def applicable_file?(file)
      includes = Array(@config['include']).flatten.map do |glob|
        Overcommit::Utils.convert_glob_to_absolute(glob)
      end

      included = includes.empty? || includes.any? do |glob|
        Overcommit::Utils.matches_path?(glob, file)
      end

      excludes = Array(@config['exclude']).flatten.map do |glob|
        Overcommit::Utils.convert_glob_to_absolute(glob)
      end

      excluded = excludes.any? do |glob|
        Overcommit::Utils.matches_path?(glob, file)
      end

      included && !excluded
    end

    # Check for any required executables or libraries.
    #
    # Returns output if any requirements are not met.
    def check_for_requirements
      check_for_executable || check_for_libraries
    end

    # If the hook defines a required executable, check if it's in the path and
    # display the install command if one exists.
    def check_for_executable
      return unless required_executable && !in_path?(required_executable)

      output = "'#{required_executable}' is not installed, not in your PATH, " \
               'or does not have execute permissions'
      output << install_command_prompt

      output
    end

    def install_command_prompt
      if install_command = @config['install_command']
        "\nInstall it by running: #{install_command}"
      else
        ''
      end
    end

    # If the hook defines required library paths that it wants to load, attempt
    # to load them.
    def check_for_libraries
      output = []

      required_libraries.each do |library|
        begin
          require library
        rescue LoadError
          install_command = @config['install_command']
          install_command = " -- install via #{install_command}" if install_command

          output << "Unable to load '#{library}'#{install_command}"
        end
      end

      return if output.empty?

      output.join("\n")
    end

    # Converts the hook's return value into a canonical form of a tuple
    # containing status (pass/warn/fail) and output.
    #
    # This is intended to support various shortcuts for writing hooks so that
    # hook authors don't need to work with {Overcommit::Hook::Message} objects
    # for simple pass/fail hooks. It also saves you from needing to manually
    # encode logic like "if there are errors, fail; if there are warnings, warn,
    # otherwise pass." by simply returning an array of
    # {Overcommit::Hook::Message} objects.
    #
    # @param hook_return_value [Symbol, Array<Symbol,String>, Array<Message>]
    # @return [Array<Symbol,String>] tuple of status and output
    def process_hook_return_value(hook_return_value)
      if hook_return_value.is_a?(Array) &&
         (hook_return_value.first.is_a?(Message) || hook_return_value.empty?)
        # Process messages into a status and output
        Overcommit::MessageProcessor.new(
          self,
          @config['problem_on_unmodified_line'],
        ).hook_result(hook_return_value)
      else
        # Otherwise return as-is
        hook_return_value
      end
    end

    # Transforms the hook's status based on custom configuration.
    #
    # This allows users to change failures into warnings, or vice versa.
    def transform_status(status)
      case status
      when :fail
        @config.fetch('on_fail', :fail).to_sym
      when :warn
        @config.fetch('on_warn', :warn).to_sym
      else
        status
      end
    end
  end
end
