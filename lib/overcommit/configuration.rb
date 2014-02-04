module Overcommit
  # Stores configuration for Overcommit and the hooks it runs.
  class Configuration
    # Creates a configuration from the given hash.
    def initialize(hash)
      @hash = hash
      validate
    end

    def ==(other)
      super || @hash == other.hash
    end
    alias :eql? :==

    # Returns absolute path to the directory that external hook plugins should
    # be loaded from.
    def plugin_directory
      File.join(Overcommit::Utils.repo_root, @hash['plugin_directory'])
    end

    # Returns the built-in hooks that have been enabled for a hook type.
    def enabled_builtin_hooks(hook_type)
      @hash[hook_type].keys.
        select { |hook_name| hook_name != 'ALL' }.
        select { |hook_name| @hash[hook_type][hook_name]['enabled'] != false }
    end

    # Returns a non-modifiable configuration for a hook.
    def for_hook(hook, hook_type = nil)
      unless hook_type
        components = hook.class.name.split('::')
        hook = components.last
        hook_type = Overcommit::Utils.underscorize(components[-2])
      end

      # Merge hook configuration with special 'ALL' config
      smart_merge(@hash[hook_type]['ALL'], @hash[hook_type][hook] || {}).freeze
    end

    # Merges the given configuration with this one, returning a new
    # {Configuration}. The provided configuration will either add to or replace
    # any options defined in this configuration.
    def merge(config)
      self.class.new(smart_merge(@hash, config.hash))
    end

    # Applies additional configuration settings based on the provided
    # environment variables.
    def apply_environment!(hook_type, env)
      hook_type = hook_type.gsub('-', '_')

      skipped_hooks = "#{env['SKIP']} #{env['SKIP_CHECKS']}".split(/[:, ]/)

      if skipped_hooks.include?('all') || skipped_hooks.include?('ALL')
        @hash[hook_type]['ALL']['skip'] = true
      else
        skipped_hooks.select { |hook_name| hook_exists?(hook_type, hook_name) }.
                      each do |hook_name|
          @hash[hook_type][hook_name] ||= {}
          @hash[hook_type][hook_name]['skip'] = true
        end
      end
    end

  protected

    attr_reader :hash

  private

    def hook_exists?(hook_type, hook_name)
      File.exist?(File.join(OVERCOMMIT_HOME, 'lib', 'overcommit', 'hook',
                            hook_type, "#{hook_name}.rb"))
    end

    # Validates the configuration for any invalid options, normalizing it where
    # possible.
    def validate
      @hash = convert_nils_to_empty_hashes(@hash)
      ensure_hook_type_sections_exist(@hash)
    end

    def smart_merge(parent, child)
      parent.merge(child) do |key, old, new|
        case old
        when Array
          old + Array(new)
        when Hash
          smart_merge(old, new)
        else
          new
        end
      end
    end

    def ensure_hook_type_sections_exist(hash)
      hook_types = Overcommit::Utils.supported_hook_types.
                                     map { |type| type.gsub('-', '_') }

      hook_types.each do |hook_type|
        hash[hook_type] ||= {}
        hash[hook_type]['ALL'] ||= {}
      end
    end

    def convert_nils_to_empty_hashes(hash)
      hash.inject({}) do |h, (key, value)|
        h[key] =
          case value
          when nil  then {}
          when Hash then convert_nils_to_empty_hashes(value)
          else
            value
          end
        h
      end
    end
  end
end
