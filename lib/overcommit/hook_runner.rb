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
      # ASSUMPTION: we assume the setup and cleanup calls will never need to be
      # interrupted, i.e. they will finish quickly. Should further evidence
      # suggest this assumption does not hold, we will have to separately wrap
      # these calls to allow some sort of "are you sure?" double-interrupt
      # functionality, but until that's deemed necessary let's keep it simple.
      InterruptHandler.isolate_from_interrupts do
        @context.setup_environment
        load_hooks
        result = run_hooks
        @context.cleanup_environment
        result
      end
    end

    private

    attr_reader :log

    def run_hooks
      if @hooks.any?(&:enabled?)
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

        print_results(run_failed, interrupted)

        !(run_failed || interrupted)
      else
        @printer.nothing_to_run
        true # Run was successful
      end
    end

    def print_results(failed, interrupted)
      if interrupted
        @printer.run_interrupted
      elsif failed
        @printer.run_failed
      else
        @printer.run_succeeded
      end
    end

    def run_hook(hook)
      return if should_skip?(hook)

      @printer.start_hook(hook)

      status, output = nil, nil

      begin
        # Disable the interrupt handler during individual hook run so that
        # Ctrl-C actually stops the current hook from being run, but doesn't
        # halt the entire process.
        InterruptHandler.disable_until_finished_or_interrupted do
          status, output = hook.run_and_transform
        end
      rescue => ex
        status = :fail
        output = "Hook raised unexpected error\n#{ex.message}\n#{ex.backtrace.join("\n")}"
      rescue Interrupt
        # At this point, interrupt has been handled and protection is back in
        # effect thanks to the InterruptHandler.
        status = :interrupt
        output = 'Hook was interrupted by Ctrl-C; restoring repo state...'
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
          # Tell user if hook was skipped only if it actually would have run
          @printer.hook_skipped(hook) if hook.run?
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
