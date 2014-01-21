module Overcommit::HookRunner
  # Hook runners are responsible for loading the hooks the repository has
  # configured and running them, collecting the results.
  class Base
    def initialize(config)
      @config = config
      @hooks = []
    end

    # Loads and runs the hooks registered for this {HookRunner}.
    def run(args, input, logger)
      @args = args
      @input = input
      @logger = logger

      # stash_unstaged_files
      load_hooks
      run_hooks
    ensure
      # restore_unstaged_files
    end

    # Returns the type of hook this runner deals with (e.g. "CommitMsg",
    # "PreCommit", etc.)
    def hook_type
      @hook_type ||= self.class.name.split('::').last
    end

    def underscored_hook_type
      @underscored_hook_type ||= Overcommit::Utils.underscorize(hook_type)
    end

    # Get a list of added, copied, or modified files that have been staged.
    # Renames and deletions are ignored, since there should be nothing to check.
    def staged_files
      @staged_files ||=
        `git diff --cached --name-only --diff-filter=ACM --ignore-submodules=all`.
          split("\n").
          map { |relative_file| File.expand_path(relative_file) }
    end

  private

    def run_hooks
      reporter = Overcommit::Reporter.new(self, @hooks, @config, @logger)

      reporter.start_hook_run

      @hooks.select { |hook| hook.run? }.
             each do |hook|
        reporter.with_status(hook) do
          hook.run
        end
      end

      reporter.finish_hook_run
      reporter.checks_passed?
    end

    # Loads hooks that will be run.
    # This is done explicitly so that we only load hooks which will actually be
    # used.
    def load_hooks
      require "overcommit/hook/#{underscored_hook_type}/base"

      load_builtin_hooks
      load_hook_plugins # Load after so they can subclass/modify existing hooks
    end

    # Load hooks that ship with Overcommit, ignoring ones that are excluded from
    # the repository's configuration.
    def load_builtin_hooks
      @config.enabled_hooks(underscored_hook_type).each do |hook_name|
        underscored_hook_name = Overcommit::Utils.underscorize(hook_name)
        require "overcommit/hook/#{underscored_hook_type}/#{underscored_hook_name}"
        @hooks << create_hook(hook_name)
      end
    end

    # Load hooks that are stored with the repository (i.e. are custom for the
    # repository).
    def load_hook_plugins
      directory = File.join(@config.plugin_directory, underscored_hook_type)

      Dir[File.join(directory, '*.rb')].sort do |plugin|
        require plugin

        hook_name = self.class.hook_type_to_class_name(File.basename(plugin, '.rb'))
        @hooks << create_hook(hook_name)
      end
    end

    # Load and return a {Hook} from a CamelCase hook name and the given
    # hook configuration.
    def create_hook(hook_name)
      Overcommit::Hook.const_get("#{hook_type}::#{hook_name}").
                       new(@config, self)
    rescue LoadError, NameError => error
      raise Overcommit::Exceptions::HookLoadError,
            "Unable to load hook '#{hook_name}': #{error}",
            error.backtrace
    end

    # Stashes untracked files and unstaged changes so that those changes aren't
    # read by the hooks.
    def stash_unstaged_files
      # TODO: store mtime of all stashed files with File.new('blah').mtime
      `git stash save --keep-index --include-untracked --quiet #{<<-MSG}`
        "Stash of repo state before hook run - #{Time.now}"
      MSG
    end

    # Restores the stashed files after hook has run.
    #
    # Assumes that any hooks that might have manipulated the stash have properly
    # left the stash in its original state.
    def restore_unstaged_files
      # TODO: Restore mtime of all stashed files with
      # FileUtils.touch('blah'), :mtime => time
      `git stash pop --quiet`
    end
  end
end
