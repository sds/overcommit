# encoding: utf-8

module Overcommit
  # Responsible for loading the hooks the repository has configured and running
  # them, collecting and displaying the results.
  class HookRunner
    # @param config [Overcommit::Configuration]
    # @param logger [Overcommit::Logger]
    # @param context [Overcommit::HookContext]
    # @param input [Overcommit::UserInput]
    def initialize(config, logger, context, input)
      @config = config
      @log = logger
      @context = context
      @input = input
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
        log.bold "Running #{hook_script_name} hooks"

        interrupted = false
        run_failed = false

        @hooks.each do |hook|
          hook_status = run_hook(hook)

          run_failed = true if hook_status == :bad

          if hook_status == :interrupted
            # Stop running any more hooks and assume a bad result
            interrupted = true
            break [:bad]
          end
        end.compact

        log.log # Newline
        print_summary(run_failed, interrupted)
        log.log # Newline

        !(run_failed || interrupted)
      else
        log.success "✓ No applicable #{hook_script_name} hooks to run"
        true # Run was successful
      end
    end

    def run_hook(hook)
      return if should_skip?(hook)

      unless hook.quiet?
        print_header(hook)
      end

      begin
        # Disable the interrupt handler during individual hook run so that
        # Ctrl-C actually stops the current hook from being run, but doesn't
        # halt the entire process.
        InterruptHandler.disable!
        status, output = hook.run
      rescue => ex
        status = :bad
        output = "Hook raised unexpected error\n#{ex.message}"
      rescue Interrupt
        status = :interrupted
        output = 'Hook was interrupted by Ctrl-C; restoring repo state...'
      ensure
        InterruptHandler.enable!
      end

      # Want to print the header in the event the result wasn't good so that the
      # user knows what failed
      print_header(hook) if hook.quiet? && status != :good

      print_result(hook, status, output)

      status
    end

    def print_header(hook)
      log.partial hook.description
      log.partial '.' * (70 - hook.description.length)
    end

    def should_skip?(hook)
      return true unless hook.enabled?

      if hook.skip?
        if hook.required?
          log.warning "Cannot skip #{hook.name} since it is required"
        else
          log.warning "Skipping #{hook.name}"
          return true
        end
      end

      !hook.run?
    end

    def print_result(hook, status, output)
      case status
      when :good
        log.success 'OK' unless hook.quiet?
      when :warn
        log.warning 'WARNING'
        print_report(output, :bold_warning)
      when :bad
        log.error 'FAILED'
        print_report(output, :bold_error)
      when :interrupted
        log.error 'INTERRUPTED'
        print_report(output, :bold_error)
      end
    end

    def print_report(output, format = :log)
      log.send(format, output) unless output.nil? || output.empty?
    end

    def print_summary(run_failed, was_interrupted)
      if was_interrupted
        log.warning '⚠  Hook run interrupted by user'
      elsif run_failed
        log.error "✗ One or more #{hook_script_name} hooks failed"
      else
        log.success "✓ All #{hook_script_name} hooks passed"
      end
    end

    def load_hooks
      require "overcommit/hook/#{@context.hook_type_name}/base"

      @hooks += HookLoader::BuiltInHookLoader.new(@config, @context, @log, @input).load_hooks

      # Load plugin hooks after so they can subclass existing hooks
      @hooks += HookLoader::PluginHookLoader.new(@config, @context, @log, @input).load_hooks
    end

    def hook_script_name
      @context.hook_script_name
    end
  end
end
