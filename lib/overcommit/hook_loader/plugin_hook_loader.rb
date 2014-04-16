require 'digest'

module Overcommit::HookLoader
  # Responsible for loading hooks that are specific to the repository Overcommit
  # is running in.
  class PluginHookLoader < Base
    def load_hooks
      directory = File.join(@config.plugin_directory, @context.hook_type_name)

      plugin_paths = Dir[File.join(directory, '*.rb')].sort

      check_for_modified_plugins(plugin_paths) if @config.verify_plugin_signatures?

      plugin_paths.map do |plugin_path|
        require plugin_path
        create_hook(hook_name(plugin_path))
      end
    end

  private

    def check_for_modified_plugins(plugin_paths)
      modified_plugins = plugin_paths.select do |plugin_path|
        signature_changed?(plugin_path)
      end

      return if modified_plugins.empty?

      log.bold_warning "The following #{@context.hook_script_name} plugins " \
                       "have been added or changed:"
      log.log

      modified_plugins.each do |plugin_path|
        log.warning " * #{hook_name(plugin_path)} in #{plugin_path}"
      end

      log.log
      log.bold_warning 'You should verify the changes before continuing'
      log.log "For more information, see #{Overcommit::REPO_URL}#security"
      log.log
      log.partial 'Continue? (y/n) '

      unless (answer = @input.get) && answer.strip.downcase.start_with?('y')
        raise Overcommit::Exceptions::HookCancelled
      end

      modified_plugins.each { |plugin_path| update_signature(plugin_path) }
    end

    def hook_name(plugin_path)
      Overcommit::Utils.camel_case(File.basename(plugin_path, '.rb'))
    end

    def signature_changed?(plugin_path)
      calculate_signature(plugin_path) != stored_signature(plugin_path)
    end

    # Calculates a hash of a plugin using a combination of its configuration and
    # file contents.
    #
    # This way, if either the plugin code changes or its configuration changes,
    # the hash will change and we can alert the user to this change.
    def calculate_signature(plugin_path)
      hook_config = @config.for_hook(hook_name(plugin_path), @context.hook_class_name)

      Digest::SHA256.hexdigest(File.open(plugin_path, 'r').read + hook_config.to_s)
    end

    def stored_signature(plugin_path)
      result = Overcommit::Utils.execute(
        %w[git config --local --get] + [signature_config_key(plugin_path)]
      )

      if result.status == 1 # Key doesn't exist
        return ''
      elsif result.status != 0
        raise Overcommit::Exceptions::GitConfigError,
              "Unable to read from local repo git config: #{result.stderr}"
      end

      result.stdout.chomp
    end

    def update_signature(plugin_path)
      result = Overcommit::Utils.execute(
        %w[git config --local] +
        [signature_config_key(plugin_path), calculate_signature(plugin_path)]
      )

      unless result.success?
        raise Overcommit::Exceptions::GitConfigError,
              "Unable to write to local repo git config: #{result.stderr}"
      end
    end

    def signature_config_key(plugin_path)
      "overcommit.#{@context.hook_class_name}.#{hook_name(plugin_path)}.signature"
    end
  end
end
