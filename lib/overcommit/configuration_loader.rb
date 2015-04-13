require 'yaml'

module Overcommit
  # Manages configuration file loading.
  class ConfigurationLoader
    DEFAULT_CONFIG_PATH = File.join(Overcommit::HOME, 'config', 'default.yml')

    class << self
      # Loads and returns the default configuration.
      #
      # @return [Overcommit::Configuration]
      def default_configuration
        @default_config ||= load_from_file(DEFAULT_CONFIG_PATH, default: true)
      end

      # Loads configuration from file.
      #
      # @param file [String] path to file
      # @param options [Hash]
      # @option default [Boolean] whether this is the default built-in configuration
      # @option logger [Overcommit::Logger]
      # @return [Overcommit::Configuration]
      def load_from_file(file, options = {})
        hash =
          if yaml = YAML.load_file(file)
            yaml.to_hash
          else
            {}
          end

        Overcommit::Configuration.new(hash, options)
      end
    end

    # Create a configuration loader which writes warnings/errors to the given
    # {Overcommit::Logger} instance.
    def initialize(logger)
      @log = logger
    end

    # Loads and returns the configuration for the repository we're running in.
    #
    # @return [Overcommit::Configuration]
    def load_repo_config
      overcommit_yml = File.join(Overcommit::Utils.repo_root,
                                 Overcommit::CONFIG_FILE_NAME)

      if File.exist?(overcommit_yml)
        load_file(overcommit_yml)
      else
        self.class.default_configuration
      end
    end

    # Loads a configuration, ensuring it extends the default configuration.
    def load_file(file)
      config = self.class.load_from_file(file, default: false, logger: @log)

      self.class.default_configuration.merge(config)
    rescue => error
      raise Overcommit::Exceptions::ConfigurationError,
            "Unable to load configuration from '#{file}': #{error}",
            error.backtrace
    end
  end
end
