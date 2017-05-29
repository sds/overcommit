require 'digest'
require 'json'

module Overcommit
  # Stores configuration for Overcommit and the hooks it runs.
  class Configuration # rubocop:disable ClassLength
    # Creates a configuration from the given hash.
    #
    # @param hash [Hash] loaded YAML config file as a hash
    # @param options [Hash]
    # @option default [Boolean] whether this is the default built-in configuration
    # @option logger [Overcommit::Logger]
    def initialize(hash, options = {})
      @options = options.dup
      @options[:logger] ||= Overcommit::Logger.silent
      @hash = hash # Assign so validator can read original values
      unless options[:validate] == false
        @hash = Overcommit::ConfigurationValidator.new.validate(self, hash, options)
      end
    end

    def ==(other)
      super || @hash == other.hash
    end

    # Access the configuration as if it were a hash.
    #
    # @param key [String]
    # @return [Array,Hash,Number,String]
    def [](key)
      @hash[key]
    end

    # Returns absolute path to the directory that external hook plugins should
    # be loaded from.
    def plugin_directory
      File.join(Overcommit::Utils.repo_root, @hash['plugin_directory'] || '.git-hooks')
    end

    def concurrency
      @concurrency ||=
        begin
          cores = Overcommit::Utils.processor_count
          content = @hash.fetch('concurrency', '%<processors>d')
          if content.is_a?(String)
            concurrency_expr = content % { processors: cores }

            a, op, b = concurrency_expr.scan(%r{(\d+)\s*([+\-*\/])\s*(\d+)})[0]
            if a
              a.to_i.send(op, b.to_i)
            else
              concurrency_expr.to_i
            end
          else
            content.to_i
          end
        end
    end

    # Returns configuration for all hooks in each hook type.
    #
    # @return [Hash]
    def all_hook_configs
      smart_merge(all_builtin_hook_configs, all_plugin_hook_configs)
    end

    # Returns configuration for all built-in hooks in each hook type.
    #
    # @return [Hash]
    def all_builtin_hook_configs
      hook_configs = {}

      Overcommit::Utils.supported_hook_type_classes.each do |hook_type|
        hook_names = @hash[hook_type].keys.reject { |name| name == 'ALL' }

        hook_configs[hook_type] = Hash[
          hook_names.map do |hook_name|
            [hook_name, for_hook(hook_name, hook_type)]
          end
        ]
      end

      hook_configs
    end

    # Returns configuration for all plugin hooks in each hook type.
    #
    # @return [Hash]
    def all_plugin_hook_configs
      hook_configs = {}

      Overcommit::Utils.supported_hook_types.each do |hook_type|
        hook_type_class_name = Overcommit::Utils.camel_case(hook_type)

        directory = File.join(plugin_directory, hook_type.tr('-', '_'))
        plugin_paths = Dir[File.join(directory, '*.rb')].sort

        hook_names = plugin_paths.map do |path|
          Overcommit::Utils.camel_case(File.basename(path, '.rb'))
        end

        hook_configs[hook_type_class_name] = Hash[
          hook_names.map do |hook_name|
            [hook_name, for_hook(hook_name, Overcommit::Utils.camel_case(hook_type))]
          end
        ]
      end

      hook_configs
    end

    # Returns the built-in hooks that have been enabled for a hook type.
    def enabled_builtin_hooks(hook_context)
      @hash[hook_context.hook_class_name].keys.
        reject { |hook_name| hook_name == 'ALL' }.
        select { |hook_name| built_in_hook?(hook_context, hook_name) }.
        select { |hook_name| hook_enabled?(hook_context, hook_name) }
    end

    # Returns the ad hoc hooks that have been enabled for a hook type.
    def enabled_ad_hoc_hooks(hook_context)
      @hash[hook_context.hook_class_name].keys.
        reject { |hook_name| hook_name == 'ALL' }.
        select { |hook_name| ad_hoc_hook?(hook_context, hook_name) }.
        select { |hook_name| hook_enabled?(hook_context, hook_name) }
    end

    # Returns a non-modifiable configuration for a hook.
    def for_hook(hook, hook_type = nil)
      unless hook_type
        components = hook.class.name.split('::')
        hook = components.last
        hook_type = components[-2]
      end

      # Merge hook configuration with special 'ALL' config
      hook_config = smart_merge(@hash[hook_type]['ALL'], @hash[hook_type][hook] || {})

      # Need to specially handle `enabled` option since not setting it does not
      # necessarily mean the hook is disabled
      hook_config['enabled'] = hook_enabled?(hook_type, hook)

      hook_config.freeze
    end

    # Merges the given configuration with this one, returning a new
    # {Configuration}. The provided configuration will either add to or replace
    # any options defined in this configuration.
    def merge(config)
      self.class.new(smart_merge(@hash, config.hash))
    end

    # Applies additional configuration settings based on the provided
    # environment variables.
    def apply_environment!(hook_context, env)
      skipped_hooks = "#{env['SKIP']} #{env['SKIP_CHECKS']} #{env['SKIP_HOOKS']}".split(/[:, ]/)
      only_hooks = env.fetch('ONLY', '').split(/[:, ]/)
      hook_type = hook_context.hook_class_name

      if only_hooks.any? || skipped_hooks.include?('all') || skipped_hooks.include?('ALL')
        @hash[hook_type]['ALL']['skip'] = true
      end

      only_hooks.select { |hook_name| hook_exists?(hook_context, hook_name) }.
                 map { |hook_name| Overcommit::Utils.camel_case(hook_name) }.
                 each do |hook_name|
        @hash[hook_type][hook_name] ||= {}
        @hash[hook_type][hook_name]['skip'] = false
      end

      skipped_hooks.select { |hook_name| hook_exists?(hook_context, hook_name) }.
                    map { |hook_name| Overcommit::Utils.camel_case(hook_name) }.
                    each do |hook_name|
        @hash[hook_type][hook_name] ||= {}
        @hash[hook_type][hook_name]['skip'] = true
      end
    end

    def plugin_hook?(hook_context_or_type, hook_name)
      hook_type_name =
        if hook_context_or_type.is_a?(String)
          Overcommit::Utils.snake_case(hook_context_or_type)
        else
          hook_context_or_type.hook_type_name
        end
      hook_name = Overcommit::Utils.snake_case(hook_name)

      File.exist?(File.join(plugin_directory, hook_type_name, "#{hook_name}.rb"))
    end

    # Return whether the signature for this configuration has changed since it
    # was last calculated.
    #
    # @return [true,false]
    def signature_changed?
      signature != stored_signature
    end

    # Return whether a previous signature has been recorded for this
    # configuration.
    #
    # @return [true,false]
    def previous_signature?
      !stored_signature.empty?
    end

    # Returns whether this configuration should verify itself by checking the
    # stored configuration for the repo.
    #
    # @return [true,false]
    def verify_signatures?
      return false if ENV['OVERCOMMIT_NO_VERIFY']
      return true if @hash['verify_signatures'] != false

      result = Overcommit::Utils.execute(
        %W[git config --local --get #{verify_signature_config_key}]
      )

      if result.status == 1 # Key doesn't exist
        return true
      elsif result.status != 0
        raise Overcommit::Exceptions::GitConfigError,
              "Unable to read from local repo git config: #{result.stderr}"
      end

      # We don't cast since we want to allow anything to count as "true" except
      # a literal zero
      result.stdout.strip != '0'
    end

    # Update the currently stored signature for this hook.
    def update_signature!
      result = Overcommit::Utils.execute(
        %w[git config --local] + [signature_config_key, signature]
      )

      verify_signature_value = @hash['verify_signatures'] ? 1 : 0
      result &&= Overcommit::Utils.execute(
        %W[git config --local #{verify_signature_config_key} #{verify_signature_value}]
      )

      unless result.success?
        raise Overcommit::Exceptions::GitConfigError,
              "Unable to write to local repo git config: #{result.stderr}"
      end
    end

    protected

    attr_reader :hash

    private

    def ad_hoc_hook?(hook_context, hook_name)
      ad_hoc_conf = @hash.fetch(hook_context.hook_class_name, {}).fetch(hook_name, {})

      # Ad hoc hooks are neither built-in nor have a plugin file written but
      # still have a `command` specified to be run
      !built_in_hook?(hook_context, hook_name) &&
        !plugin_hook?(hook_context, hook_name) &&
        (ad_hoc_conf['command'] || ad_hoc_conf['required_executable'])
    end

    def built_in_hook?(hook_context, hook_name)
      hook_name = Overcommit::Utils.snake_case(hook_name)

      File.exist?(File.join(Overcommit::HOME, 'lib', 'overcommit', 'hook',
                            hook_context.hook_type_name, "#{hook_name}.rb"))
    end

    def hook_exists?(hook_context, hook_name)
      built_in_hook?(hook_context, hook_name) ||
        plugin_hook?(hook_context, hook_name) ||
        ad_hoc_hook?(hook_context, hook_name)
    end

    def hook_enabled?(hook_context_or_type, hook_name)
      hook_type =
        if hook_context_or_type.is_a?(String)
          hook_context_or_type
        else
          hook_context_or_type.hook_class_name
        end

      individual_enabled = @hash[hook_type].fetch(hook_name, {})['enabled']
      return individual_enabled unless individual_enabled.nil?

      all_enabled = @hash[hook_type]['ALL']['enabled']
      return all_enabled unless all_enabled.nil?

      false
    end

    def smart_merge(parent, child)
      # Treat the ALL hook specially so that it overrides any configuration
      # specified by the default configuration.
      child_all = child['ALL']
      unless child_all.nil?
        parent = Hash[parent.collect { |k, v| [k, smart_merge(v, child_all)] }]
      end

      parent.merge(child) do |_key, old, new|
        case old
        when Hash
          smart_merge(old, new)
        else
          new
        end
      end
    end

    # Returns the unique signature of this configuration.
    #
    # @return [String]
    def signature
      Digest::SHA256.hexdigest(@hash.to_json)
    end

    # Returns the stored signature of this repo's Overcommit configuration.
    #
    # This is intended to be compared against the current signature of this
    # configuration object.
    #
    # @return [String]
    def stored_signature
      result = Overcommit::Utils.execute(
        %w[git config --local --get] + [signature_config_key]
      )

      if result.status == 1 # Key doesn't exist
        return ''
      elsif result.status != 0
        raise Overcommit::Exceptions::GitConfigError,
              "Unable to read from local repo git config: #{result.stderr}"
      end

      result.stdout.chomp
    end

    def signature_config_key
      'overcommit.configuration.signature'
    end

    def verify_signature_config_key
      'overcommit.configuration.verifysignatures'
    end
  end
end
