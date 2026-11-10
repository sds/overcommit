# frozen_string_literal: true

require 'overcommit/utils/messages_utils'

module Overcommit::HookLoader
  # Responsible for loading hooks from a file.
  class Base
    # @param config [Overcommit::Configuration]
    # @param context [Overcommit::HookContext]
    # @param logger [Overcommit::Logger]
    def initialize(config, context, logger)
      @config = config
      @context = context
      @log = logger
    end

    # When implemented in subclasses, loads the hooks for which that subclass is
    # responsible.
    #
    # @return [Array<Hook>]
    def load_hooks
      raise NotImplementedError
    end

    private

    def validate_line_aware_config(hook_config)
      pattern = hook_config['message_pattern']
      unless pattern.is_a?(Regexp) && pattern.names.include?('file')
        raise Overcommit::Exceptions::HookLoadError,
              '`message_pattern` must be a Regexp with a named `file` capture group'
      end

      warning_pattern = hook_config['warning_message_type_pattern']
      unless warning_pattern.nil? || warning_pattern.is_a?(Regexp) || warning_pattern.is_a?(String)
        raise Overcommit::Exceptions::HookLoadError,
              '`warning_message_type_pattern` must be a Regexp or String'
      end
    end

    def create_line_aware_command_hook_class(hook_base)
      Class.new(hook_base) do
        def run
          result = execute(command, args: applicable_files)
          return :pass if result.success?

          output = result.stdout.split("\n")
          return [:fail, result.stderr] if output.empty?

          Overcommit::Utils::MessagesUtils.extract_messages(
            output,
            @config['message_pattern'],
            Overcommit::Utils::MessagesUtils.create_type_categorizer(
              @config['warning_message_type_pattern']
            )
          )
        end
      end
    end

    attr_reader :log

    # Load and return a {Hook} from a CamelCase hook name.
    def create_hook(hook_name)
      hook_type_class = Overcommit::Hook.const_get(@context.hook_class_name)
      hook_base_class = hook_type_class.const_get(:Base)
      hook_class = hook_type_class.const_get(hook_name, false)
      unless hook_class.is_a?(Class) && hook_class < hook_base_class
        raise Overcommit::Exceptions::HookLoadError,
              "Class #{hook_name} is not a subclass of #{hook_base_class}."
      end

      hook_class.new(@config, @context)
    rescue LoadError, NameError => e
      raise Overcommit::Exceptions::HookLoadError,
            "Unable to load hook '#{hook_name}': #{e}",
            e.backtrace
    end
  end
end
