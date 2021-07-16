# frozen_string_literal: true

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

    # GNU/Emacs-style error format:
    AD_HOC_HOOK_DEFAULT_MESSAGE_PATTERN =
      /^(?<file>(?:\w:)?[^:]+):(?<line>\d+):[^ ]* (?<type>[^ ]+)/.freeze

    def is_hook_line_aware(hook_config)
      hook_config['extract_messages_from'] ||
        hook_config['message_pattern'] ||
        hook_config['warning_message_type_pattern']
    end

    def create_line_aware_command_hook_class(hook_base) # rubocop:disable Metrics/MethodLength
      Class.new(hook_base) do
        def line_aware_config
          {
            message_pattern: @config['message_pattern'],
            warning_message_type_pattern: @config['warning_message_type_pattern']
          }
        end

        def run
          result = execute(command, args: applicable_files)

          return :pass if result.success?

          extract_messages(line_aware_config, result)
        end

        def extract_messages(line_aware_config, result)
          warning_message_type_pattern = line_aware_config[:warning_message_type_pattern]
          Overcommit::Utils::MessagesUtils.extract_messages(
            result.stdout.split("\n"),
            line_aware_config[:message_pattern] ||
              AD_HOC_HOOK_DEFAULT_MESSAGE_PATTERN,
            Overcommit::Utils::MessagesUtils.create_type_categorizer(
              warning_message_type_pattern
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
      hook_class = hook_type_class.const_get(hook_name)
      unless hook_class < hook_base_class
        raise Overcommit::Exceptions::HookLoadError,
              "Class #{hook_name} is not a subclass of #{hook_base_class}."
      end

      begin
        Overcommit::Hook.const_get(@context.hook_class_name).
                         const_get(hook_name).
                         new(@config, @context)
      rescue LoadError, NameError => e
        raise Overcommit::Exceptions::HookLoadError,
              "Unable to load hook '#{hook_name}': #{e}",
              e.backtrace
      end
    end
  end
end
