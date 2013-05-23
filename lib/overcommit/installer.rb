require 'fileutils'
require 'yaml'

module Overcommit
  class Installer
    def initialize(options = {})
      @options = options
    end

    def install(target)
      absolute_target = File.expand_path(target)
      unless File.directory? absolute_target
        raise NotAGitRepoError, 'is a directory'
      end

      unless File.directory?(File.join(absolute_target, '.git'))
        raise NotAGitRepoError, 'does not appear to be a git repository'
      end

      puts "Installing hooks into #{target}"
      hook_path = File.join(absolute_target, '.git/hooks')

      install_scripts(hook_path)
      install_hooks(hook_path)
      write_configuration(hook_path)
    end

  private

    # Make helper scripts available locally inside the repo
    def install_scripts(target)
      FileUtils.cp_r Utils.absolute_path('bin/scripts'), target
    end

    # Install all available git hooks into the repo
    def install_hooks(target)
      Dir[Utils.absolute_path('bin/hooks/*')].each do |hook|
        FileUtils.cp hook, File.join(target, File.basename(hook))
      end
    end

    # Dump a YAML document containing requested configuration
    def write_configuration(target)
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

      File.open(File.join(target, 'overcommit.yml'), 'w') do |config|
        YAML.dump(base_config, config)
      end
    end
  end
end
