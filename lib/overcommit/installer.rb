require 'fileutils'

module Overcommit
  # Manages the installation of Overcommit hooks in a git repository.
  class Installer
    def initialize(logger)
      @log = logger
    end

    def run(target, options)
      @target = target
      @options = options
      validate_target
      @options[:action] == :uninstall ? uninstall : install
    end

  private

    attr_reader :log

    def install
      log.log "Installing hooks into #{@target}"

      install_master_hook
      install_hook_symlinks

      log.success "Successfully installed hooks into #{@target}"
    end

    def uninstall
      log.log "Removing hooks from #{@target}"

      uninstall_master_hook
      uninstall_hook_symlinks

      log.success "Successfully removed hooks from #{@target}"
    end

    def hooks_path
      absolute_target = File.expand_path(@target)
      File.join(absolute_target, '.git', 'hooks')
    end

    def validate_target
      absolute_target = File.expand_path(@target)

      unless File.directory?(absolute_target)
        raise Overcommit::Exceptions::InvalidGitRepo, 'is not a directory'
      end

      unless File.directory?(File.join(absolute_target, '.git'))
        raise Overcommit::Exceptions::InvalidGitRepo, 'does not appear to be a git repository'
      end
    end

    def install_master_hook
      master_hook = File.join(OVERCOMMIT_HOME, 'libexec', 'overcommit-hook')
      install_location = File.join(hooks_path, 'overcommit-hook')
      FileUtils.mkdir_p(hooks_path)
      FileUtils.cp(master_hook, install_location)
    end

    def uninstall_master_hook
      install_location = File.join(hooks_path, 'overcommit-hook')
      FileUtils.rm_rf(install_location)
    end

    def install_hook_symlinks
      # Link each hook type (pre-commit, commit-msg, etc.) to the master hook.
      # We change directories so that the relative symlink paths work regardless
      # of where the repository is located.
      Dir.chdir(hooks_path) do
        Overcommit::Utils.supported_hook_types.each do |hook_type|
          unless can_replace_file?(hook_type)
            raise Overcommit::Exceptions::PreExistingHooks,
                  "Hook '#{File.expand_path(hook_type)}' already exists and was not installed by Overcommit"
          end
          FileUtils.ln_sf('overcommit-hook', hook_type)
        end
      end
    end

    def can_replace_file?(file)
      @options[:force] ||
        !File.exists?(file) ||
        overcommit_symlink?(file)
    end

    def uninstall_hook_symlinks
      Dir.chdir(hooks_path) do
        Overcommit::Utils.supported_hook_types.each do |hook_type|
          FileUtils.rm_rf(hook_type) if overcommit_symlink?(hook_type)
        end
      end
    end

    def overcommit_symlink?(file)
      File.symlink?(file) && File.readlink(file) == 'overcommit-hook'
    end
  end
end
