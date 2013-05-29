require 'singleton'
require 'yaml'

module Overcommit
  class Configuration
    include Singleton

    attr_reader :templates

    def initialize
      @templates = YAML.load_file(Utils.absolute_path('config/templates.yml'))
    end

    # Read the repo-specific 'overcommit.yml' file to determine what behavior
    # the user wants.
    def repo_settings
      config_file = Utils.repo_path('.git/hooks/overcommit.yml')

      File.exist?(config_file) ? YAML.load_file(config_file) : {}
    end

    # Given the current configuration, return a set of paths which should be
    # loaded as plugins (`require`d)
    def desired_plugins
      excludes = repo_settings['excludes']

      plugin_directories.map do |dir|
        Dir[File.join(dir, Utils.hook_name, '*.rb')].map do |plugin|
          basename = File.basename(plugin, '.rb')
          if !(excludes[Utils.hook_name] || []).include?(basename)
            plugin
          end
        end.compact
      end.flatten
    end

  private

    def plugin_directories
      # Start with the base plugins provided by the gem
      plugin_dirs   = [File.expand_path('../plugins', __FILE__)]
      repo_specific = Utils.repo_path('.githooks')

      # Add on any repo-specific checks
      plugin_dirs << repo_specific if File.directory?(repo_specific)

      plugin_dirs
    end
  end

  def self.config
    Configuration.instance
  end
end
