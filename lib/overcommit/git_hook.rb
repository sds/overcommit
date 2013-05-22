module Overcommit
  module GitHook
    class BaseHook
      include ConsoleMethods

      def initialize
        skip_checks = ENV.fetch('SKIP_CHECKS', '').split(/[:, ]/)
        return if skip_checks.include? 'all'

        plugin_dirs   = [File.expand_path('../plugins', __FILE__)]
        repo_specific = Utils.repo_path('.githooks')

        plugin_dirs << repo_specific if File.directory?(repo_specific)

        plugin_dirs.each do |dir|
          Dir[File.join(dir, Utils.hook_name, '*.rb')].each do |plugin|
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
      end

      def run(*args)
        # Support 'bare' installation where we don't have any hooks yet.
        # Silently pass.
        exit unless (checks = HookRegistry.checks) && checks.any?

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
            check.run_check
          end
        end

        reporter.print_result
      end

    private

      # If true, only run this check when there are modified files.
      def requires_modified_files?
        false
      end
    end
  end
end
