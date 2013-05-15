require 'pathname'

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
          Dir[File.join(dir, Overcommit::Utils.hook_name, '*.rb')].each do |plugin|
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
        exit if requires_modified_files? && modified_files.empty?

        reporter = Reporter.new(Overcommit::Utils.hook_name, HookRegistry.checks)

        reporter.print_header

        HookRegistry.checks.each do |check_class|
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
