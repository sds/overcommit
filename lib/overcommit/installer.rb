require 'fileutils'
require 'yaml'

module Overcommit
  class Installer
    def initialize(options, target)
      @options = options
      @target  = target
    end

    def run
      validate_target
      @options[:uninstall] ? uninstall : install
    end

    def install
      log.log "Installing hooks into #{@target}"

      install_scripts
      install_hooks
      write_configuration
    end

    def uninstall
      log.log "Removing hooks from #{@target}"

      uninstall_scripts
      uninstall_hooks
      rm_configuration
    end

  private

    def log
      Logger.instance
    end

    def hook_path
      absolute_target = File.expand_path @target
      File.join(absolute_target, '.git/hooks')
    end

    def validate_target
      absolute_target = File.expand_path @target
      unless File.directory? absolute_target
        raise NotAGitRepoError, 'is not a directory'
      end

      unless File.directory?(File.join(absolute_target, '.git'))
        raise NotAGitRepoError, 'does not appear to be a git repository'
      end
    end

    # Make helper scripts available locally inside the repo
    def install_scripts
      FileUtils.cp_r Utils.absolute_path('bin/scripts'), hook_path
    end

    # Install all available git hooks into the repo
    def install_hooks
      hooks.each do |hook|
        FileUtils.cp hook, File.join(hook_path, File.basename(hook))
      end
    end

    def uninstall_hooks
      hooks.each do |hook|
        delete File.join(hook_path, File.basename(hook))
      end
    end

    def uninstall_scripts
      scripts = File.join(hook_path, 'scripts')
      FileUtils.rm_r scripts rescue false
    end

    def hooks
      Dir[Utils.absolute_path('bin/hooks/*')]
    end

    # Dump a YAML document containing requested configuration
    def write_configuration
      template = @options.fetch(:template, 'default')
      base_config = Overcommit.config.templates[template]
      if base_config.nil?
        raise ArgumentError, "No such template '#{template}'"
      end

      base_config = base_config.dup
      (base_config['excludes'] ||= {}).
        merge!(@options[:excludes] || {}) do |_, a, b|
        # Concat the arrays together
        a + b
      end

      File.open(configuration_location, 'w') do |config|
        YAML.dump(base_config, config)
      end
    end

    def rm_configuration
      delete configuration_location
    end

    def configuration_location
      File.join(hook_path, 'overcommit.yml')
    end

    def delete(file)
      File.delete file rescue false
    end
  end
end
