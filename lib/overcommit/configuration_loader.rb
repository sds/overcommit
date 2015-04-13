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
        @default_config ||= load_from_file(DEFAULT_CONFIG_PATH)
      end

      # Loads a configuration, ensuring it extends the default configuration.
      def load_file(file)
        config = load_from_file(file)

        default_configuration.merge(config)
      rescue => error
        raise Overcommit::Exceptions::ConfigurationError,
              "Unable to load configuration from '#{file}': #{error}",
              error.backtrace
      end

      private

      def load_from_file(file)
        hash =
          if yaml = YAML.load_file(file)
            yaml.to_hash
          else
            {}
          end

        Overcommit::Configuration.new(hash)
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
        self.class.load_file(overcommit_yml)
      else
        self.class.default_configuration
      end
    end
  end
end
