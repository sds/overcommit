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
  MESSAGE_TYPES = [:error, :warning]

  # Functionality common to all hooks.
  class Base
    extend Forwardable

    def_delegators :@context, :modified_files
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
      if output = check_for_executable
        status = :fail
      else
        status, output = process_hook_return_value(run)
      end

      [transform_status(status), output]
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
         hook_return_value.first.is_a?(Message)
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

    def name
      self.class.name.split('::').last
    end

    def description
      @config['description'] || "Running #{name}"
    end

    def required?
      @config['required']
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
        (!skip? || required?) &&
        !(@config['requires_files'] && applicable_files.empty?)
    end

    def in_path?(cmd)
      Overcommit::Utils.in_path?(cmd)
    end

    def execute(cmd)
      Overcommit::Utils.execute(cmd)
    end

    def executable
      @config['required_executable']
    end

    # Gets a list of staged files that apply to this hook based on its
    # configured `include` and `exclude` lists.
    def applicable_files
      @applicable_files ||= modified_files.select { |file| applicable_file?(file) }
    end

    private

    def applicable_file?(file)
      includes = Array(@config['include']).map do |glob|
        Overcommit::Utils.convert_glob_to_absolute(glob)
      end

      included = includes.empty? || includes.any? do |glob|
        Overcommit::Utils.matches_path?(glob, file)
      end

      excludes = Array(@config['exclude']).map do |glob|
        Overcommit::Utils.convert_glob_to_absolute(glob)
      end

      excluded = excludes.any? do |glob|
        Overcommit::Utils.matches_path?(glob, file)
      end

      included && !excluded
    end

    # If the hook defines a required executable, check if it's in the path and
    # display the install command if one exists.
    def check_for_executable
      return unless executable && !in_path?(executable)

      output = "'#{executable}' is not installed (or is not in your PATH)"

      if install_command = @config['install_command']
        output += "\nInstall it by running: #{install_command}"
      end

      output
    end

    # Transforms the hook's status based on custom configuration.
    #
    # This allows users to change failures into warnings, or vice versa.
    def transform_status(status)
      case status
      when :fail, :bad
        @config.fetch('on_fail', :fail).to_sym
      when :warn
        @config.fetch('on_warn', :warn).to_sym
      else
        status
      end
    end
  end
end
