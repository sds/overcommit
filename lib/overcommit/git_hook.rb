module Overcommit
  module GitHook
    class BaseHook
      def initialize
        Overcommit.config.desired_plugins.each do |plugin|
          require plugin
        end
      rescue LoadError, NameError => ex
        log.error "Couldn't load plugin: #{ex}"
        exit 0
      end

      def run(*args)
        # Support 'bare' installation where we don't have any hooks yet.
        # Silently pass.
        exit unless (checks = registered_checks) && checks.any?

        exit if requires_modified_files? && Utils.modified_files.empty?

        reporter = Reporter.new(Overcommit::Utils.hook_name, checks)

        reporter.print_header

        checks.each do |check_class|
          check = check_class.new(*args)
          next if check.skip?

          # Ignore a check if it only applies to a specific file type and there
          # are no staged files of that type in the tree
          next if check_class.filetype && check.staged.empty?

          reporter.with_status(check) do
            run_and_filter_check(check)
          end
        end

        reporter.print_result
      end

      def skip_checks
        @skip_checks ||= ENV.fetch('SKIP_CHECKS', '').split(/[:, ]/)
      end

    private

      def log
        Logger.instance
      end

      # Return all loaded plugins, skipping those that are skippable and have
      # been asked to be skipped by the environment variable SKIP_CHECKS.
      #
      # Note that required checks are not skipped even if
      # `ENV['SKIP_CHECKS'] == 'all'`
      def registered_checks
        @registered_checks ||= begin
          skip_all = skip_checks.include? 'all'
          HookRegistry.checks.reject do |check|
            hook_name = Utils.underscorize(check.name).split('/').last

            check.skippable? && (skip_all || skip_checks.include?(hook_name))
          end.sort_by(&:name)
        end
      end

      # If true, only run this check when there are modified files.
      def requires_modified_files?
        false
      end

      # Filters temporary staged file names from the output of the check and
      # replaces them with their original filenames.
      def run_and_filter_check(check)
        status, output = check.run_check

        if output && !output.empty?
          check.staged.each do |staged_file|
            output = staged_file.filter_string(output)
          end
        end

        [status, output]
      end
    end
  end
end
