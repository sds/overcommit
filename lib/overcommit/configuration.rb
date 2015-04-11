module Overcommit
  # Stores configuration for Overcommit and the hooks it runs.
  class Configuration # rubocop:disable ClassLength
    # Creates a configuration from the given hash.
    def initialize(hash)
      @hash = ConfigurationValidator.new.validate(hash)
    end

    def ==(other)
      super || @hash == other.hash
    end
    alias_method :eql?, :==

    # Returns absolute path to the directory that external hook plugins should
    # be loaded from.
    def plugin_directory
      File.join(Overcommit::Utils.repo_root, @hash['plugin_directory'] || '.githooks')
    end

    def verify_plugin_signatures?
      @hash['verify_plugin_signatures'] != false
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

        directory = File.join(plugin_directory, hook_type.gsub('-', '_'))
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
        select { |hook_name| hook_name != 'ALL' }.
        select { |hook_name| built_in_hook?(hook_context, hook_name) }.
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
      hook_type = hook_context.hook_class_name

      if skipped_hooks.include?('all') || skipped_hooks.include?('ALL')
        @hash[hook_type]['ALL']['skip'] = true
      else
        skipped_hooks.select { |hook_name| hook_exists?(hook_context, hook_name) }.
                      map { |hook_name| Overcommit::Utils.camel_case(hook_name) }.
                      each do |hook_name|
          @hash[hook_type][hook_name] ||= {}
          @hash[hook_type][hook_name]['skip'] = true
        end
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

    protected

    attr_reader :hash

    private

    def built_in_hook?(hook_context, hook_name)
      hook_name = Overcommit::Utils.snake_case(hook_name)

      File.exist?(File.join(OVERCOMMIT_HOME, 'lib', 'overcommit', 'hook',
                            hook_context.hook_type_name, "#{hook_name}.rb"))
    end

    def hook_exists?(hook_context, hook_name)
      built_in_hook?(hook_context, hook_name) ||
        plugin_hook?(hook_context, hook_name)
    end

    def hook_enabled?(hook_context_or_type, hook_name)
      hook_type = hook_context_or_type.is_a?(String) ? hook_context_or_type :
                                                       hook_context_or_type.hook_class_name

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
  end
end
