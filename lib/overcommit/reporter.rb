module Overcommit
  # Reports the results of running hooks.
  class Reporter
    attr_reader :log

    def initialize(context, hooks, config, log)
      @log     = log
      @config  = config
      @name    = Overcommit::Utils.underscorize(context.hook_class_name).gsub('_', '-')
      @hooks   = hooks
      @width   = [(@hooks.map { |s| s.description.length }.max || 57) + 3, 60].max
      @results = []
    end

    def start_hook_run
      log.bold "Running #{@name} checks"
    end

    def with_status(hook, &block)
      title = "  #{hook.description}"
      unless hook.quiet?
        log.partial title
        log.partial '.' * (@width - title.length)
      end

      status, output = yield

      print_hook_result(hook, title, status, output)
      @results << status
    end

    def finish_hook_run
      log.log # Newline

      if checks_passed?
        log.success "✓ All #{@name} checks passed"
      else
        log.error "✗ One or more #{@name} checks failed"
      end

      log.log # Newline
    end

    def checks_passed?
      !@results.include?(:bad)
    end

  private

    def print_hook_result(hook, title, status, output)
      if hook.quiet?
        return if status == :good
        log.partial title
        log.partial '.' * (@width - title.length)
      end

      case status
      when :good
        log.success 'OK'
      when :bad
        log.error 'FAILED'
        print_report output
      when :warn
        log.warning 'WARNING'
        print_report output
      else
        log.error '???'
        print_report "Check didn't return a status"
      end
    end

    OUTPUT_INDENT = ' ' * 4
    def print_report(output)
      unless output.empty?
        # Take each line of output and add indentation so it nests under check
        # name (except for the last newline if there is one)
        output = OUTPUT_INDENT + output.gsub(/\n(?!$)/, "\n#{OUTPUT_INDENT}")
        log.log output
      end
    end
  end
end
