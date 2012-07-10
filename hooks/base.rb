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

  # We run syntax checks against the version of the file that is staged in
  # the index, not the one in the work tree. This class is a simple wrapper
  # to make working with staged files easier.
  class StagedFile
    attr_reader :contents

    def initialize path
      @original_path  = path
      @tempfile       = Tempfile.new(path.gsub('/', '_'))
      self.contents   = `git show :#{@original_path}`
    end

    # Given error output from a syntax checker, replace references to the
    # temporary file path with the original path.
    def filter_string string
      string.gsub(path, @original_path)
    end

    # The path of the temporary file on disk, suitable for feeding in to a
    # syntax checker.
    def path
      @tempfile.path
    end

    # Set or overwrite the temporary file's contents.
    #
    # This is used by the ERB syntax checker, for example, to compile
    # the template before checking.
    def contents=(contents)
      @contents = contents
      @tempfile.seek 0
      @tempfile.write @contents
      @tempfile.flush
    end
  end
end
