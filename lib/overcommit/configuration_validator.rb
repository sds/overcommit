# rubocop:disable Metrics/ClassLength, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity, Metrics/MethodLength, Metrics/LineLength
module Overcommit
  # Validates and normalizes a configuration.
  class ConfigurationValidator
    # Validates hash for any invalid options, normalizing where possible.
    #
    # @param config [Overcommit::Configuration]
    # @param hash [Hash] hash representation of YAML config
    # @param options[Hash]
    # @option default [Boolean] whether hash represents the default built-in config
    # @option logger [Overcommit::Logger] logger to output warnings to
    # @return [Hash] validated hash (potentially modified)
    def validate(config, hash, options)
      @options = options.dup
      @log = options[:logger]

      hash = convert_nils_to_empty_hashes(hash)
      ensure_hook_type_sections_exist(hash)
      check_hook_name_format(hash)
      check_hook_env(hash)
      check_for_missing_enabled_option(hash) unless @options[:default]
      check_for_too_many_processors(config, hash)
      check_for_verify_plugin_signatures_option(hash)

      hash
    end

    private

    # Ensures that keys for all supported hook types exist (PreCommit,
    # CommitMsg, etc.)
    def ensure_hook_type_sections_exist(hash)
      Overcommit::Utils.supported_hook_type_classes.each do |hook_type|
        hash[hook_type] ||= {}
        hash[hook_type]['ALL'] ||= {}
      end
    end

    # Normalizes `nil` values to empty hashes.
    #
    # This is useful for when we want to merge two configuration hashes
    # together, since it's easier to merge two hashes than to have to check if
    # one of the values is nil.
    def convert_nils_to_empty_hashes(hash)
      hash.each_with_object({}) do |(key, value), h|
        h[key] =
          case value
          when nil  then {}
          when Hash then convert_nils_to_empty_hashes(value)
          else
            value
          end
      end
    end

    def check_hook_env(hash)
      errors = []

      Overcommit::Utils.supported_hook_type_classes.each do |hook_type|
        hash.fetch(hook_type, {}).each do |hook_name, hook_config|
          hook_env = hook_config.fetch('env', {})

          unless hook_env.is_a?(Hash)
            errors << "#{hook_type}::#{hook_name} has an invalid `env` specified: " \
                      'must be a hash of environment variable name to string value.'
            next
          end

          hook_env.each do |var_name, var_value|
            if var_name.include?('=')
              errors << "#{hook_type}::#{hook_name} has an invalid `env` specified: " \
                        "variable name `#{var_name}` cannot contain `=`."
            end

            unless var_value.nil? || var_value.is_a?(String)
              errors << "#{hook_type}::#{hook_name} has an invalid `env` specified: " \
                        "value of `#{var_name}` must be a string or `nil`, but was " \
                        "#{var_value.inspect} (#{var_value.class})"
            end
          end
        end
      end

      if errors.any?
        @log.error errors.join("\n") if @log
        @log.newline if @log
        raise Overcommit::Exceptions::ConfigurationError,
              'One or more hooks had an invalid `env` configuration option'
      end
    end

    # Prints an error message and raises an exception if a hook has an
    # invalid name, since this can result in strange errors elsewhere.
    def check_hook_name_format(hash)
      errors = []

      Overcommit::Utils.supported_hook_type_classes.each do |hook_type|
        hash.fetch(hook_type, {}).each_key do |hook_name|
          next if hook_name == 'ALL'

          unless hook_name =~ /\A[A-Za-z0-9]+\z/
            errors << "#{hook_type}::#{hook_name} has an invalid name " \
                      "#{hook_name}. It must contain only alphanumeric " \
                      'characters (no underscores or dashes, etc.)'
          end
        end
      end

      if errors.any?
        @log.error errors.join("\n") if @log
        @log.newline if @log
        raise Overcommit::Exceptions::ConfigurationError,
              'One or more hooks had invalid names'
      end
    end

    # Prints a warning if there are any hooks listed in the configuration
    # without `enabled` explicitly set.
    def check_for_missing_enabled_option(hash)
      return unless @log

      any_warnings = false

      Overcommit::Utils.supported_hook_type_classes.each do |hook_type|
        hash.fetch(hook_type, {}).each do |hook_name, hook_config|
          next if hook_name == 'ALL'

          if hook_config['enabled'].nil?
            @log.warning "#{hook_type}::#{hook_name} hook does not explicitly " \
                         'set `enabled` option in .overcommit.yml'
            any_warnings = true
          end
        end
      end

      @log.newline if any_warnings
    end

    # Prints a warning if any hook has a number of processors larger than the
    # global `concurrency` setting.
    def check_for_too_many_processors(config, hash)
      concurrency = config.concurrency

      errors = []
      Overcommit::Utils.supported_hook_type_classes.each do |hook_type|
        hash.fetch(hook_type, {}).each do |hook_name, hook_config|
          processors = hook_config.fetch('processors', 1)
          if processors > concurrency
            errors << "#{hook_type}::#{hook_name} `processors` value " \
                      "(#{processors}) is larger than the global `concurrency` " \
                      "option (#{concurrency})"
          end
        end
      end

      if errors.any?
        @log.error errors.join("\n") if @log
        @log.newline if @log
        raise Overcommit::Exceptions::ConfigurationError,
              'One or more hooks had invalid `processor` value configured'
      end
    end

    # Prints a warning if the `verify_plugin_signatures` option is used instead
    # of the new `verify_signatures` option.
    def check_for_verify_plugin_signatures_option(hash)
      return unless @log

      if hash.key?('verify_plugin_signatures')
        @log.warning '`verify_plugin_signatures` has been renamed to ' \
                     '`verify_signatures`. Defaulting to verifying signatures.'
        @log.warning "See change log at #{REPO_URL}/blob/v0.29.0/CHANGELOG.md for details."
        @log.newline
      end
    end
  end
end
# rubocop:enable Metrics/ClassLength, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity, Metrics/MethodLength, Metrics/LineLength
