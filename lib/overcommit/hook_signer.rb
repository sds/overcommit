module Overcommit
  # Calculates, stores, and retrieves stored signatures of hook plugins.
  class HookSigner
    attr_reader :hook_path, :hook_name

    # We don't want to include the skip setting as it is set by Overcommit
    # itself
    IGNORED_CONFIG_KEYS = %w[skip]

    # @param hook_path [String] path to the actual hook definition
    # @param config [Overcommit::Configuration]
    # @param context [Overcommit::HookContext]
    def initialize(hook_path, config, context)
      @hook_path = hook_path
      @config = config
      @context = context

      @hook_name = Overcommit::Utils.camel_case(File.basename(@hook_path, '.rb'))
    end

    # Return whether the signature for this hook has changed since it was last
    # calculated.
    #
    # @return [true,false]
    def signature_changed?
      signature != stored_signature
    end

    # Update the current stored signature for this hook.
    def update_signature!
      result = Overcommit::Utils.execute(
        %w[git config --local] + [signature_config_key, signature]
      )

      unless result.success?
        raise Overcommit::Exceptions::GitConfigError,
              "Unable to write to local repo git config: #{result.stderr}"
      end
    end

  private

    # Calculates a hash of a hook using a combination of its configuration and
    # file contents.
    #
    # This way, if either the plugin code changes or its configuration changes,
    # the hash will change and we can alert the user to this change.
    def signature
      hook_config = @config.for_hook(@hook_name, @context.hook_class_name).
                            dup.
                            tap { |config| IGNORED_CONFIG_KEYS.each { |k| config.delete(k) } }

      Digest::SHA256.hexdigest(hook_contents + hook_config.to_s)
    end

    def hook_contents
      File.open(@hook_path, 'r').read
    end

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
      "overcommit.#{@context.hook_class_name}.#{@hook_name}.signature"
    end
  end
end
