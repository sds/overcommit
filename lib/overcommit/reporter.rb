module Overcommit
  class Reporter
    include ConsoleMethods

    def initialize(name, checks)
      @name    = name
      @checks  = checks
      @width   = 70 - (@checks.map { |s| s.name.length }.max || 0)
      @results = []
    end

    def with_status(check, &block)
      title = "  Checking #{check.name}..."
      print title unless check.stealth?

      status, output = yield

      print_incremental_result(title, status, output, check.stealth?)
      @results << status
    end

    def print_header
      puts "Running #{@name} checks"
    end

    def print_incremental_result(title, status, output, stealth = false)
      if stealth
        return if status == :good
        print title
      end

      print '.' * (@width - title.length)
      case status
      when :good
        success 'OK'
      when :bad
        error 'FAILED'
        print_report output
      when :warn
        warning output
      when :stop
        warning 'UH OH'
        print_report output
      else
        error '???'
        print_report "Check didn't return a status"
        exit 1
      end
    end

    def print_result
      puts
      case final_result
      when :good
        success "+++ All #{@name} checks passed"
        exit 0
      when :bad
        error "!!! One or more #{@name} checks failed"
        exit 1
      when :stop
        warning "*** One or more #{@name} checks needs attention"
        warning "*** If you really want to commit, use SKIP_CHECKS"
        warning "*** (takes a space-separated list of checks to skip, or 'all')"
        exit 1
      end
    end

  private

    def final_result
      return :bad  if @results.include?(:bad)
      return :stop if @results.include?(:stop)
      return :good
    end

    def print_report(*report)
      puts report.flatten.map{ |line| "    #{line}" }.join("\n")
    end
  end
end
