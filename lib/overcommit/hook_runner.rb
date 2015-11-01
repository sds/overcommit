module Overcommit
  # Responsible for loading the hooks the repository has configured and running
  # them, collecting and displaying the results.
  class HookRunner # rubocop:disable Metrics/ClassLength
    # @param config [Overcommit::Configuration]
    # @param logger [Overcommit::Logger]
    # @param context [Overcommit::HookContext]
    # @param printer [Overcommit::Printer]
    def initialize(config, logger, context, printer)
      @config = config
      @log = logger
      @context = context
      @printer = printer
      @hooks = []

      @lock = Mutex.new
      @resource = ConditionVariable.new
      @main = ConditionVariable.new
      @slots_available = @config.concurrency
      @hooks_finished = 0
    end

    # Loads and runs the hooks registered for this {HookRunner}.
    def run
      # ASSUMPTION: we assume the setup and cleanup calls will never need to be
      # interrupted, i.e. they will finish quickly. Should further evidence
      # suggest this assumption does not hold, we will have to separately wrap
      # these calls to allow some sort of "are you sure?" double-interrupt
      # functionality, but until that's deemed necessary let's keep it simple.
      InterruptHandler.isolate_from_interrupts do
        # Load hooks before setting up the environment so that the repository
        # has not been touched yet. This way any load errors at this point don't
        # result in Overcommit leaving the repository in a bad state.
        load_hooks

        # Setup the environment without automatically calling
        # `cleanup_environment` on an error. This is because it's possible that
        # the `setup_environment` code did not fully complete, so there's no
        # guarantee that `cleanup_environment` will be able to accomplish
        # anything of value. The safest thing to do is therefore nothing in the
        # unlikely case of failure.
        @context.setup_environment

        begin
          run_hooks
        ensure
          @context.cleanup_environment
        end
      end
    end

    private

    attr_reader :log

    def run_hooks
      if @hooks.any?(&:enabled?)
        @printer.start_run

        @threads = @hooks.map { |hook| Thread.new(hook, &method(:run_hook)) }

        begin
          InterruptHandler.disable_until_finished_or_interrupted do
            start_and_wait_for_workers
          end
        rescue Interrupt
          @printer.interrupt_triggered
          # We received an interrupt on the main thread, so alert the
          # remaining workers that an exception occurred
          @interrupted = true
          @threads.each { |thread| thread.raise Interrupt }
        end

        calculate_results
        print_results

        !(@failed || @interrupted)
      else
        @printer.nothing_to_run
        true # Run was successful
      end
    end

    def start_and_wait_for_workers
      @resource.signal

      @lock.synchronize do
        @main.wait(@lock)
      end
    end

    def wait_for_slot(hook)
      @lock.synchronize do
        slots_needed = hook.parallelize? ? 1 : @config.concurrency

        loop do
          @resource.wait(@lock)

          if @slots_available >= slots_needed
            @slots_available -= slots_needed
            @resource.signal if @slots_available > 0
            break
          elsif @slots_available > 0
            # It's possible that another hook that requires fewer slots can be
            # served, so give another a chance
            @resource.signal
          end
        end
      end
    end

    def release_slot(hook)
      @lock.synchronize do
        slots_released = hook.parallelize? ? 1 : @config.concurrency
        @slots_available += slots_released
        @hooks_finished += 1

        if @hooks_finished < @hooks.size
          # Signal once. `wait_for_slot` will perform additional signals if
          # there are still slots available. This prevents us from sending out
          # useless signals
          @resource.signal
        else
          # Otherwise signal the main thread that we're done!
          @main.signal
        end
      end
    end

    def calculate_results
      return if @interrupted

      @failed = false
      @warned = false

      @threads.each do |thread|
        hook_status, _hook_output = thread.value
        @failed = true if hook_status == :fail
        @warned = true if hook_status == :warn
      end
    end

    def print_results
      if @interrupted
        @printer.run_interrupted
      elsif @failed
        @printer.run_failed
      elsif @warned
        @printer.run_warned
      else
        @printer.run_succeeded
      end
    end

    def run_hook(hook)
      Thread.handle_interrupt(Interrupt => :immediate) do
        status, output = nil, nil

        begin
          wait_for_slot(hook)
          return if should_skip?(hook)

          status, output = hook.run_and_transform
        rescue => ex
          status = :fail
          output = "Hook raised unexpected error\n#{ex.message}\n#{ex.backtrace.join("\n")}"
        end

        @printer.end_hook(hook, status, output) unless @interrupted

        status
      end
    rescue Interrupt
      @interrupted = true
    ensure
      release_slot(hook)
    end

    def should_skip?(hook)
      return true if @interrupted || !hook.enabled?

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

      @hooks += HookLoader::BuiltInHookLoader.new(@config, @context, @log).load_hooks

      # Load plugin hooks after so they can subclass existing hooks
      @hooks += HookLoader::PluginHookLoader.new(@config, @context, @log).load_hooks
    rescue LoadError => ex
      # Include a more helpful message that will probably save some confusion
      message = 'A load error occurred. ' +
        if @config['gemfile']
          "Did you forget to specify a gem in your `#{@config['gemfile']}`?"
        else
          'Did you forget to install a gem?'
        end

      raise Overcommit::Exceptions::HookLoadError,
            "#{message}\n#{ex.message}",
            ex.backtrace
    end
  end
end
