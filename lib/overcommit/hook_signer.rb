module Overcommit
  # Calculates, stores, and retrieves stored signatures of hook plugins.
  class HookSigner
    attr_reader :hook_name

    # We don't want to include the skip setting as it is set by Overcommit
    # itself
    IGNORED_CONFIG_KEYS = %w[skip].freeze

    # @param hook_name [String] name of the hook
    # @param config [Overcommit::Configuration]
    # @param context [Overcommit::HookContext]
    def initialize(hook_name, config, context)
      @hook_name = hook_name
      @config = config
      @context = context
    end

    # Returns the path of the file that should be incorporated into this hooks
    # signature.
    #
    # @return [String]
    def hook_path
      @hook_path ||= begin
        plugin_path = File.join(@config.plugin_directory,
                                @context.hook_type_name,
                                "#{Overcommit::Utils.snake_case(@hook_name)}.rb")

        if File.exist?(plugin_path)
          plugin_path
        else
          # Otherwise this is an ad hoc hook using an existing hook script
          hook_config = @config.for_hook(@hook_name, @context.hook_class_name)

          command = Array(hook_config['command'] || hook_config['required_executable'])

          if @config.verify_signatures? &&
            signable_file?(command.first) &&
            !Overcommit::GitRepo.tracked?(command.first)
            raise Overcommit::Exceptions::InvalidHookDefinition,
                  'Hook specified a `required_executable` or `command` that ' \
                  'is a path relative to the root of the repository, and so ' \
                  'must be tracked by Git in order to be signed'
          end

          File.join(Overcommit::Utils.repo_root, command.first.to_s)
        end
      end
    end

    def signable_file?(file)
      return unless file
      sep = Overcommit::OS.windows? ? '\\' : File::SEPARATOR
      file.start_with?(".#{sep}") ||
        file.start_with?(Overcommit::Utils.repo_root)
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

      content_to_sign =
        if signable_file?(hook_path) && Overcommit::GitRepo.tracked?(hook_path)
          hook_contents
        end

      Digest::SHA256.hexdigest(content_to_sign.to_s + hook_config.to_s)
    end

    def hook_contents
      File.read(hook_path)
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
