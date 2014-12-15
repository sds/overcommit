require 'digest'

module Overcommit::HookLoader
  # Responsible for loading hooks that are specific to the repository Overcommit
  # is running in.
  class PluginHookLoader < Base
    def load_hooks
      check_for_modified_plugins if @config.verify_plugin_signatures?

      plugin_paths.map do |plugin_path|
        require plugin_path

        hook_name = Overcommit::Utils.camel_case(File.basename(plugin_path, '.rb'))
        create_hook(hook_name)
      end
    end

    def update_signatures
      log.success('No plugin signatures have changed') if modified_plugins.empty?

      modified_plugins.each do |plugin|
        plugin.update_signature!
        log.warning "Updated signature of plugin #{plugin.hook_name}"
      end
    end

    private

    def plugin_paths
      directory = File.join(@config.plugin_directory, @context.hook_type_name)
      Dir[File.join(directory, '*.rb')].sort
    end

    def modified_plugins
      plugin_paths.
        map { |path| Overcommit::HookSigner.new(path, @config, @context) }.
        select(&:signature_changed?)
    end

    def check_for_modified_plugins
      return if modified_plugins.empty?

      log.bold_warning "The following #{@context.hook_script_name} plugins " \
                       'have been added, changed, or had their configuration modified:'
      log.newline

      modified_plugins.each do |signer|
        log.warning " * #{signer.hook_name} in #{signer.hook_path}"
      end

      log.newline
      log.bold_warning 'You should verify the changes and then run:'
      log.newline
      log.warning "overcommit --sign #{@context.hook_script_name}"
      log.newline
      log.log "For more information, see #{Overcommit::REPO_URL}#security"

      raise Overcommit::Exceptions::InvalidHookSignature
    end
  end
end
