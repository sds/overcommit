module Overcommit
  # Responsible for loading the hooks the repository has configured and running
  # them, collecting and displaying the results.
  class HookRunner
    def initialize(config, logger, context)
      @config = config
      @logger = logger
      @context = context
      @hooks = []
    end

    # Loads and runs the hooks registered for this {HookRunner}.
    def run
      load_hooks
      @context.setup_environment
      run_hooks
    ensure
      @context.cleanup_environment
    end

  private

    def run_hooks
      reporter = Overcommit::Reporter.new(@context, @hooks, @config, @logger)

      reporter.start_hook_run

      @hooks.select { |hook| hook.run? }.
             each do |hook|
        reporter.with_status(hook) do
          hook.run
        end
      end

      reporter.finish_hook_run
      reporter.checks_passed?
    end

    # Loads hooks that will be run.
    # This is done explicitly so that we only load hooks which will actually be
    # used.
    def load_hooks
      require "overcommit/hook/#{@context.hook_type_name}/base"

      load_builtin_hooks
      load_hook_plugins # Load after so they can subclass/modify existing hooks
    end

    # Load hooks that ship with Overcommit, ignoring ones that are excluded from
    # the repository's configuration.
    def load_builtin_hooks
      @config.enabled_builtin_hooks(@context.hook_class_name).each do |hook_name|
        underscored_hook_name = Overcommit::Utils.snake_case(hook_name)
        require "overcommit/hook/#{@context.hook_type_name}/#{underscored_hook_name}"
        @hooks << create_hook(hook_name)
      end
    end

    # Load hooks that are stored with the repository (i.e. are custom for the
    # repository).
    def load_hook_plugins
      directory = File.join(@config.plugin_directory, @context.hook_type_name)

      Dir[File.join(directory, '*.rb')].sort do |plugin|
        require plugin

        # TODO: FIX this!
        hook_name = self.class.hook_type_to_class_name(File.basename(plugin, '.rb'))
        @hooks << create_hook(hook_name)
      end
    end

    # Load and return a {Hook} from a CamelCase hook name and the given
    # hook configuration.
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
