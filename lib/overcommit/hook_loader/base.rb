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

    attr_reader :log

    # Load and return a {Hook} from a CamelCase hook name.
    def create_hook(hook_name)
      Overcommit::Hook.const_get(@context.hook_class_name).
                       const_get(hook_name).
                       new(@config, @context)
    rescue LoadError, NameError => error
      raise Overcommit::Exceptions::HookLoadError,
            "Unable to load hook '#{hook_name}': #{error}",
            error.backtrace
    end
  end
end
