require 'yaml'

module Overcommit
  # Manages configuration file loading.
  class ConfigurationLoader
    DEFAULT_CONFIG_PATH = File.join(OVERCOMMIT_HOME, 'config', 'default.yml')
    FILE_NAME = '.overcommit.yml'

    def self.load_repo_config
      overcommit_yml = File.join(Overcommit::Utils.repo_root, FILE_NAME)

      if File.exists?(overcommit_yml)
        load_file(overcommit_yml)
      else
        default_configuration
      end
    end

    def self.default_configuration
      @default_config ||= load_from_file(DEFAULT_CONFIG_PATH)
    end

  private

    # Loads a configuration, ensuring it extends the default configuration.
    def self.load_file(file)
      config = load_from_file(file)

      default_configuration.merge(config)
    rescue => error
      raise Overcommit::Exceptions::ConfigurationError,
            "Unable to load configuration from '#{file}': #{error}",
            error.backtrace
    end

    def self.load_from_file(file)
      hash =
        if yaml = YAML.load_file(file)
          yaml.to_hash
        else
          {}
        end

      Overcommit::Configuration.new(hash)
    end
  end
end
