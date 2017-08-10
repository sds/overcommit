require 'fileutils'

module Overcommit
  # Calculates, stores, and retrieves stored signatures of hook plugins.
  class HookSigner # rubocop:disable Metrics/ClassLength
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

          command = Array(hook_config['command'] ||
                          hook_config['required_executable'])

          unless !@config.verify_signatures? || signable_file?(command.first)
            raise Overcommit::Exceptions::InvalidHookDefinition,
                  'Hook must specify a `required_executable` or `command` that ' \
                  'is tracked by git (i.e. is a path relative to the root ' \
                  'of the repository) so that it can be signed'
          end

          File.join(Overcommit::Utils.repo_root, command.first)
        end
      end
    end

    def signable_file?(file)
      sep = Overcommit::OS.windows? ? '\\' : File::SEPARATOR
      file.start_with?(".#{sep}") &&
        Overcommit::GitRepo.tracked?(file)
    end

    # Return whether the signature for this hook has changed since it was last
    # calculated.
    #
    # @return [true,false]
    def signature_changed?
      changed = signature != stored_signature

      if changed && has_history_file
        changed = !signature_in_history_file(signature)
      end

      changed
    end

    # Update the current stored signature for this hook.
    def update_signature!
      updated_signature = signature

      result = Overcommit::Utils.execute(
        %w[git config --local] + [signature_config_key, updated_signature]
      )

      unless result.success?
        raise Overcommit::Exceptions::GitConfigError,
              "Unable to write to local repo git config: #{result.stderr}"
      end

      add_signature_to_history(updated_signature)
    end

    private

    def add_signature_to_history(signature)
      # Now we must update the history file with the new signature
      # We want to put the newest signatures at the top, since they are more
      # likely to be used, and will be read sooner
      signatures = []
      if has_history_file
        signatures = (File.readlines history_file).first(@config.signature_history - 1)
      else
        FileUtils.mkdir_p(File.dirname(history_file))
      end

      File.open(history_file, 'w') do |fh|
        fh.write("#{signature}\n")
        signatures.each do |old_signature|
          fh.write(old_signature)
        end
      end
    end

    def signature_in_history_file(signature)
      unless has_history_file
        return false
      end

      found = false
      File.open(history_file, 'r') do |fh|
        # Process the header
        until (line = fh.gets).nil?
          line.chomp

          if line == signature
            found = true
            break
          end
        end
      end

      found
    end

    # Does the history file exist
    def has_history_file
      STDERR.puts 'checking history file'
      File.exist?(history_file)
    end

    # Determine the absolute path for this signer's history file
    def history_file
      File.join(@config.hook_signature_directory,
                @context.hook_type_name,
                "#{Overcommit::Utils.snake_case(@hook_name)}.rb")
    end

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
