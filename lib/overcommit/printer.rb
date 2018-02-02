require 'monitor'

module Overcommit
  # Provide a set of callbacks which can be executed as events occur during the
  # course of {HookRunner#run}.
  class Printer
    attr_reader :log

    def initialize(config, logger, context)
      @config = config
      @log = logger
      @context = context
      @lock = Monitor.new # Need to use monitor so we can have re-entrant locks
      synchronize_all_methods
    end

    # Executed at the very beginning of running the collection of hooks.
    def start_run
      log.bold "Running #{hook_script_name} hooks" unless @config['quiet']
    end

    def nothing_to_run
      log.debug "✓ No applicable #{hook_script_name} hooks to run"
    end

    def hook_skipped(hook)
      log.warning "Skipping #{hook.name}"
    end

    def required_hook_not_skipped(hook)
      log.warning "Cannot skip #{hook.name} since it is required"
    end

    # Executed at the end of an individual hook run.
    def end_hook(hook, status, output)
      # Want to print the header for quiet hooks only if the result wasn't good
      # so that the user knows what failed
      print_header(hook) if (!hook.quiet? && !@config['quiet']) || status != :pass

      print_result(hook, status, output)
    end

    def interrupt_triggered
      log.newline
      log.error 'Interrupt signal received. Stopping hooks...'
    end

    # Executed when a hook run was interrupted/cancelled by user.
    def run_interrupted
      log.newline
      log.warning '⚠  Hook run interrupted by user'
      log.newline
    end

    # Executed when one or more hooks by the end of the run.
    def run_failed
      log.newline
      log.error "✗ One or more #{hook_script_name} hooks failed"
      log.newline
    end

    # Executed when no hooks failed by the end of the run, but some warned.
    def run_warned
      log.newline
      log.warning "⚠ All #{hook_script_name} hooks passed, but with warnings"
      log.newline
    end

    # Executed when no hooks failed by the end of the run.
    def run_succeeded
      unless @config['quiet']
        log.newline
        log.success "✓ All #{hook_script_name} hooks passed"
        log.newline
      end
    end

    def hook_run_failed(message)
      log.newline
      log.log message
      log.newline
    end

    private

    def print_header(hook)
      hook_name = "[#{hook.name}] "
      log.partial hook.description
      log.partial '.' * [70 - hook.description.length - hook_name.length, 0].max
      log.partial hook_name
    end

    def print_result(hook, status, output) # rubocop:disable Metrics/CyclomaticComplexity
      case status
      when :pass
        log.success 'OK' unless @config['quiet'] || hook.quiet?
      when :warn
        log.warning 'WARNING'
        print_report(output, :bold_warning)
      when :fail
        log.error 'FAILED'
        print_report(output, :bold_error)
      when :interrupt
        log.error 'INTERRUPTED'
        print_report(output, :bold_error)
      else
        log.error '???'
        print_report("Hook returned unknown status `#{status.inspect}` -- ignoring.",
                     :bold_error)
      end
    end

    def print_report(output, format = :log)
      log.send(format, output) unless output.nil? || output.empty?
    end

    def hook_script_name
      @context.hook_script_name
    end

    # Get all public methods that were defined on this class and wrap them with
    # synchronization locks so we ensure the output isn't interleaved amongst
    # the various threads.
    def synchronize_all_methods
      methods = self.class.instance_methods - self.class.superclass.instance_methods

      methods.each do |method_name|
        old_method = :"old_#{method_name}"
        new_method = :"synchronized_#{method_name}"

        self.class.__send__(:alias_method, old_method, method_name)

        self.class.send(:define_method, new_method) do |*args|
          @lock.synchronize { __send__(old_method, *args) }
        end

        self.class.__send__(:alias_method, method_name, new_method)
      end
    end
  end
end
