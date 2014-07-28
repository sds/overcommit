module Overcommit
  # Responsible for loading the hooks the repository has configured and running
  # them, collecting and displaying the results.
  class HookRunner
    # @param config [Overcommit::Configuration]
    # @param logger [Overcommit::Logger]
    # @param context [Overcommit::HookContext]
    # @param input [Overcommit::UserInput]
    def initialize(config, logger, context, input, printer)
      @config = config
      @log = logger
      @context = context
      @input = input
      @printer = printer
      @hooks = []
    end

    # Loads and runs the hooks registered for this {HookRunner}.
    def run
      InterruptHandler.isolate_from_interrupts do
        @context.setup_environment
        load_hooks
        run_hooks
      end
    ensure
      @context.cleanup_environment
    end

  private

    attr_reader :log

    def run_hooks
      if @hooks.any? { |hook| hook.run? || hook.skip? }
        @printer.start_run

        interrupted = false
        run_failed = false

        @hooks.each do |hook|
          hook_status = run_hook(hook)

          run_failed = true if [:bad, :fail].include?(hook_status)

          if hook_status == :interrupt
            # Stop running any more hooks and assume a bad result
            interrupted = true
            break
          end
        end

        @printer.end_run(run_failed, interrupted)

        !(run_failed || interrupted)
      else
        @printer.nothing_to_run
        true # Run was successful
      end
    end

    def run_hook(hook)
      return if should_skip?(hook)

      @printer.start_hook(hook)

      begin
        # Disable the interrupt handler during individual hook run so that
        # Ctrl-C actually stops the current hook from being run, but doesn't
        # halt the entire process.
        InterruptHandler.disable!
        status, output = hook.run_and_transform
      rescue => ex
        status = :fail
        output = "Hook raised unexpected error\n#{ex.message}"
      rescue Interrupt
        status = :interrupt
        output = 'Hook was interrupted by Ctrl-C; restoring repo state...'
      ensure
        InterruptHandler.enable!
      end

      @printer.end_hook(hook, status, output)

      status
    end

    def should_skip?(hook)
      return true unless hook.enabled?

      if hook.skip?
        if hook.required?
          @printer.required_hook_not_skipped(hook)
        else
          @printer.hook_skipped(hook)
          return true
        end
      end

      !hook.run?
    end

    def load_hooks
      require "overcommit/hook/#{@context.hook_type_name}/base"

      @hooks += HookLoader::BuiltInHookLoader.new(@config, @context, @log, @input).load_hooks

      # Load plugin hooks after so they can subclass existing hooks
      @hooks += HookLoader::PluginHookLoader.new(@config, @context, @log, @input).load_hooks
    end
  end
end
