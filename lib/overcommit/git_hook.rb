require 'erb'
require 'tempfile'
require 'pathname'
require 'yaml'

module Overcommit
  module GitHook
    # File.expand_path takes one more '..' than you're used to... we want to
    # go two directories up from the caller (which will be .git/hooks/something)
    # to the root of the git repo, then down into .githooks
    REPO_SPECIFIC_DIR = File.expand_path('../../../.githooks', $0)

    @@extensions = []

    class << self
      def register_hook(base)
        @@extensions << base
      end

      def run_hooks(*args)
        @@extensions.each { |ext| ext.new.run(*args) }
      end
    end

    class BaseHook
      include FileMethods
      include ConsoleMethods

      def initialize
        skip_checks = ENV.fetch('SKIP_CHECKS', '').split(/[:, ]/)
        return if skip_checks.include? 'all'

        # Relative paths + symlinks == great fun
        plugin_dirs = [File.join(File.dirname(Pathname.new(__FILE__).realpath),
                                 'plugins')]
        plugin_dirs << REPO_SPECIFIC_DIR if File.directory?(REPO_SPECIFIC_DIR)

        plugin_dirs.each do |dir|
          Dir[File.join(dir, hook_name, '*.rb')].each do |plugin|
            unless skip_checks.include? File.basename(plugin, '.rb')
              begin
                require plugin
              rescue NameError => ex
                error "Couldn't load #{plugin}: #{ex}"
                exit 0
              end
            end
          end
        end

        @width = 70 - (HookRegistry.checks.map { |s| s.name.length }.max || 0)
      end

      def run(*args)
        exit if requires_modified_files? && modified_files.empty?

        puts "Running #{hook_name} checks"
        results = HookRegistry.checks.map do |check_class|
          check = check_class.new(*args)
          next if check.skip?

          # Ignore a check if it only applies to a specific file type and there
          # are no staged files of that type in the tree
          next if check_class.filetype && check.staged.empty?

          title = "  Checking #{check.name}..."
          print title unless check.stealth?

          status, output = check.run_check

          print_incremental_result(title, status, output, check.stealth?)
          [status, output]
        end.compact

        print_result results
      end

      def hook_name
        Overcommit::Utils.hook_name
      end

    protected

      # If true, only run this check when there are modified files.
      def requires_modified_files?
        false
      end

      def print_incremental_result(title, status, output, stealth = false)
        if stealth
          return if status == :good
          print title
        end

        print '.' * (@width - title.length)
        case status
        when :good
          success('OK')
        when :bad
          error('FAILED')
          print_report(output)
        when :warn
          warning output
        when :stop
          warning 'UH OH'
          print_report(output)
        else
          error '???'
          print_report("Check didn't return a status")
          exit 1
        end
      end

      def print_result(results)
        puts
        case final_result(results)
        when :good
          success "+++ All #{hook_name} checks passed"
          exit 0
        when :bad
          error "!!! One or more #{hook_name} checks failed"
          exit 1
        when :stop
          warning "*** One or more #{hook_name} checks needs attention"
          warning "*** If you really want to commit, use SKIP_CHECKS"
          warning "*** (takes a space-separated list of checks to skip, or 'all')"
          exit 1
        end
      end

      def final_result(results)
        states = (results.transpose.first || []).uniq
        return :bad  if states.include?(:bad)
        return :stop if states.include?(:stop)
        return :good
      end

      def print_report(*report)
        puts report.flatten.map{ |line| "    #{line}" }.join("\n")
      end
    end
  end
end
