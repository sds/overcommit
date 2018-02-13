require 'fileutils'

module Overcommit
  # Manages the installation of Overcommit hooks in a git repository.
  class Installer # rubocop:disable ClassLength
    TEMPLATE_DIRECTORY = File.join(Overcommit::HOME, 'template-dir')
    MASTER_HOOK = File.join(TEMPLATE_DIRECTORY, 'hooks', 'overcommit-hook')

    def initialize(logger)
      @log = logger
    end

    def run(target, options)
      @target = target
      @options = options
      validate_target

      case @options[:action]
      when :uninstall then uninstall
      when :update then update
      else
        install
      end
    end

    private

    attr_reader :log

    def install
      log.log "Installing hooks into #{@target}"

      ensure_directory(hooks_path)
      preserve_old_hooks
      install_master_hook
      install_hook_files
      install_starter_config

      # Auto-sign configuration file on install
      config(verify: false).update_signature!

      log.success "Successfully installed hooks into #{@target}"
    end

    def uninstall
      log.log "Removing hooks from #{@target}"

      uninstall_hook_files
      uninstall_master_hook
      restore_old_hooks

      log.success "Successfully removed hooks from #{@target}"
    end

    # @return [true,false] whether the hooks were updated
    def update
      unless FileUtils.compare_file(MASTER_HOOK, master_hook_install_path)
        preserve_old_hooks
        install_master_hook
        install_hook_files

        log.success "Hooks updated to Overcommit version #{Overcommit::VERSION}"
        true
      end
    end

    def hooks_path
      @hooks_path ||= Dir.chdir(@target) { GitConfig.hooks_path }
    end

    def old_hooks_path
      File.join(hooks_path, 'old-hooks')
    end

    def master_hook_install_path
      File.join(hooks_path, 'overcommit-hook')
    end

    def ensure_directory(path)
      FileUtils.mkdir_p(path)
    end

    def validate_target
      absolute_target = File.expand_path(@target)

      unless File.directory?(absolute_target)
        raise Overcommit::Exceptions::InvalidGitRepo, 'is not a directory'
      end

      git_dir_check = Dir.chdir(absolute_target) do
        Overcommit::Utils.execute(%w[git rev-parse --git-dir])
      end

      unless git_dir_check.success?
        raise Overcommit::Exceptions::InvalidGitRepo, 'does not appear to be a git repository'
      end
    end

    def install_master_hook
      FileUtils.mkdir_p(hooks_path)
      FileUtils.cp(MASTER_HOOK, master_hook_install_path)
    end

    def uninstall_master_hook
      FileUtils.rm_rf(master_hook_install_path, secure: true)
    end

    def install_hook_files
      # Copy each hook type (pre-commit, commit-msg, etc.) from the master hook.
      Dir.chdir(hooks_path) do
        Overcommit::Utils.supported_hook_types.each do |hook_type|
          unless can_replace_file?(hook_type)
            raise Overcommit::Exceptions::PreExistingHooks,
                  "Hook '#{File.expand_path(hook_type)}' already exists and " \
                  'was not installed by Overcommit'
          end
          FileUtils.rm_f(hook_type)
          FileUtils.cp('overcommit-hook', hook_type)
        end
      end
    end

    def can_replace_file?(file)
      @options[:force] ||
        !File.exist?(file) ||
        overcommit_hook?(file)
    end

    def preserve_old_hooks
      return unless File.directory?(hooks_path)

      ensure_directory(old_hooks_path)
      Overcommit::Utils.supported_hook_types.each do |hook_type|
        hook_file = File.join(hooks_path, hook_type)
        unless can_replace_file?(hook_file)
          log.warning "Hook '#{File.expand_path(hook_type)}' already exists and " \
                      "was not installed by Overcommit. Moving to '#{old_hooks_path}'"
          FileUtils.mv(hook_file, old_hooks_path)
        end
      end
      # Remove old-hooks directory if empty (i.e. no old hooks were preserved)
      FileUtils.rmdir(old_hooks_path) if Dir.entries(old_hooks_path).size <= 2
    end

    def restore_old_hooks
      return unless File.directory?(old_hooks_path)

      log.log "Restoring old hooks from #{old_hooks_path}"

      Dir.chdir(old_hooks_path) do
        Overcommit::Utils.supported_hook_types.each do |hook_type|
          FileUtils.mv(hook_type, hooks_path) if File.exist?(hook_type)
        end
      end
      # Remove old-hooks directory if empty
      FileUtils.rmdir(old_hooks_path)

      log.success "Successfully restored old hooks from #{old_hooks_path}"
    end

    def uninstall_hook_files
      return unless File.directory?(hooks_path)

      Dir.chdir(hooks_path) do
        Overcommit::Utils.supported_hook_types.each do |hook_type|
          FileUtils.rm_rf(hook_type, secure: true) if overcommit_hook?(hook_type)
        end
      end
    end

    def install_starter_config
      repo_config_file = File.join(@target, Overcommit::CONFIG_FILE_NAME)

      return if File.exist?(repo_config_file)
      FileUtils.cp(File.join(Overcommit::HOME, 'config', 'starter.yml'), repo_config_file)
    end

    def overcommit_hook?(file)
      File.read(file) =~ /OVERCOMMIT_DISABLE/
    rescue Errno::ENOENT
      # Some Ruby implementations (e.g. JRuby) raise an error when the file
      # doesn't exist. Standardize the behavior to return false.
      false
    end

    # Returns the configuration for this repository.
    def config(options = {})
      Overcommit::ConfigurationLoader.new(log, options).load_repo_config
    end
  end
end
