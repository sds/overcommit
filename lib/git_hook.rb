module Causes
  class GitHook
    # override me, s'il vous plaît
    @@friendly_name = "base git-hook [somebody forgot to set me]"

    def run
      exit unless modified_files.any?

      puts "Running #{@@friendly_name} checks"
      results = []
      @checks.each do |check|
        title = "  Checking #{check}..."
        print title
        status, output = send("check_#{check}")
        results << [status, output]
        print_incremental_result(title, status, output)
      end
      print_result(results)
    end

  protected
    def print_incremental_result(title, status, output)
      print '.'*(@width - title.length)
      case status
      when :good
        success("OK")
      when :bad
        error("FAILED")
        print_report(output)
      when :warn
        warning output
      when :stop
        warning "UH OH"
        print_report(output)
      else
        error "???"
        print_report("Check didn't return a status")
        exit(1)
      end
    end

    def print_result(results)
      puts
      case final_result(results)
      when :good
        success "+++ All #{@@friendly_name} checks passed"
        exit 0
      when :bad
        error "!!! One or more #{@@friendly_name} checks failed"
        exit 1
      when :stop
        warning "*** One or more #{@@friendly_name} checks needs attention"
        warning "*** If you really want to commit, use --no-verify"
        exit 1
      end
    end

    def bold(str)
      puts "\033[1;37m#{str}\033[0m"
    end

    def error(str)
      puts "\033[31m#{str}\033[0m"
    end

    def success(str)
      puts "\033[32m#{str}\033[0m"
    end

    def warning(str)
      puts "\033[33m#{str}\033[0m"
    end

    def notice(str)
      puts "\033[1;33m#{str}\033[0m"
    end

    def final_result(results)
      states = (results.transpose.first || []).uniq
      return :bad  if states.include?(:bad)
      return :stop if states.include?(:stop)
      return :good
    end

    def print_report(*report)
      puts report.flatten.map{|line| "    #{line}"}.join("\n")
    end

    def modified_files(type=nil)
      @modified_files ||= `git diff --cached --name-only --diff-filter=ACM`.split
      type ? @modified_files.select{|f| f =~ /\.#{type}$/} : @modified_files
    end

    def staged_files(*args)
      modified_files(*args).map { |filename| StagedFile.new(filename) }
    end

    def in_path?(cmd)
      system("which #{cmd} > /dev/null 2> /dev/null")
    end
  end
end
