# encoding: utf-8

module Overcommit
  # Provide a set of callbacks which can be executed as events occur during the
  # course of {HookRunner#run}.
  class Printer
    attr_reader :log

    def initialize(logger, context)
      @log = logger
      @context = context
    end

    # Executed at the very beginning of running the collection of hooks.
    def start_run
      log.bold "Running #{hook_script_name} hooks"
    end

    def nothing_to_run
      log.success "✓ No applicable #{hook_script_name} hooks to run"
    end

    # Executed at the start of an individual hook run.
    def start_hook(hook)
      unless hook.quiet?
        print_header(hook)
      end
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
      print_header(hook) if hook.quiet? && ![:good, :pass].include?(status)

      print_result(hook, status, output)
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

    # Executed when no hooks failed by the end of the run.
    def run_succeeded
      log.newline
      log.success "✓ All #{hook_script_name} hooks passed"
      log.newline
    end

    private

    def print_header(hook)
      hook_name = "[#{hook.name}] "
      log.partial hook.description
      log.partial '.' * [70 - hook.description.length - hook_name.length, 0].max
      log.partial hook_name
    end

    def print_result(hook, status, output) # rubocop:disable CyclomaticComplexity, MethodLength
      case status
      when :pass
        log.success 'OK' unless hook.quiet?
      when :good
        log.success 'OK'
        log.bold_error 'Hook returned a status of `:good`. This is deprecated ' \
                       'in favor of `:pass` and will be removed in a future ' \
                       'version of Overcommit'
      when :warn
        log.warning 'WARNING'
        print_report(output, :bold_warning)
      when :bad
        log.error 'FAILED'
        log.bold_error 'Hook returned a status of `:bad`. This is deprecated ' \
                       'in favor of `:fail` and will be removed in a future ' \
                       'version of Overcommit'
        print_report(output, :bold_error)
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
  end
end
