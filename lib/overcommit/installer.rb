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
      @options[:uninstall] ? uninstall : install
    end

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

  private

    attr_reader :log

    def hooks_path
      absolute_target = File.expand_path(@target)
      File.join(absolute_target, '.git/hooks')
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
      delete(install_location)
    end

    def install_hook_symlinks
      # Link each hook type (pre-commit, commit-msg, etc.) to the master hook.
      # We change directories so that the relative symlink paths work regardless
      # of where the repository is located.
      Dir.chdir(hooks_path) do
        supported_hook_types.each do |hook_type|
          FileUtils.ln_sf('overcommit-hook', hook_type)
        end
      end
    end

    def uninstall_hook_symlinks
      Dir.chdir(hooks_path) do
        supported_hook_types.each do |hook_type|
          if File.symlink?(hook_type) && File.readlink(hook_type) == 'overcommit-hook'
            delete(hook_type)
          end
        end
      end
    end

    def supported_hook_types
      Dir[File.join(OVERCOMMIT_HOME, 'lib', 'overcommit', 'hook_runner', '*')].
        map { |file| File.basename(file, '.rb').gsub('_', '-') }.
        reject { |file| file == 'base' }
    end

    def delete(file)
      File.delete(file) rescue false
    end
  end
end
