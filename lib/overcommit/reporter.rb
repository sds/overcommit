module Overcommit
  class Reporter
    def initialize(name, checks)
      @name    = name
      @checks  = checks
      @width   = 70 - (@checks.map { |s| s.name.length }.max || 0)
      @results = []
    end

    def with_status(check, &block)
      title = "  Checking #{check.name}..."
      log.partial title unless check.stealth?

      status, output = yield

      print_incremental_result(title, status, output, check.stealth?)
      @results << status
    end

    def print_header
      log.log "Running #{@name} checks"
    end

    def print_result
      log.log # Newline

      case final_result
      when :good
        log.success "+++ All #{@name} checks passed"
        exit 0
      when :bad
        log.error "!!! One or more #{@name} checks failed"
        exit 1
      when :stop
        log.warning "*** One or more #{@name} checks needs attention"
        log.warning "*** If you really want to commit, use SKIP_CHECKS"
        log.warning "*** (takes a space-separated list of checks to skip, or 'all')"
        exit 1
      end
    end

  private

    def log
      Overcommit::Logger.instance
    end

    def print_incremental_result(title, status, output, stealth = false)
      if stealth
        return if status == :good
        log.partial title
      end

      print '.' * (@width - title.length)
      case status
      when :good
        log.success 'OK'
      when :bad
        log.error 'FAILED'
        print_report output
      when :warn
        log.warning output
      when :stop
        log.warning 'UH OH'
        print_report output
      else
        log.error '???'
        print_report "Check didn't return a status"
        exit 1
      end
    end

    def final_result
      return :bad  if @results.include?(:bad)
      return :stop if @results.include?(:stop)
      return :good
    end

    def print_report(*report)
      log.log report.flatten.map { |line| "    #{line}" }.join("\n")
    end
  end
end
