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

        hook_name = Overcommit::Utils.camel_case(File.basename(plugin_path, '.rb'))
        create_hook(hook_name)
      end
    end

    private

    def check_for_modified_plugins(plugin_paths)
      modified_plugins = plugin_paths.
        map { |path| Overcommit::HookSigner.new(path, @config, @context) }.
        select(&:signature_changed?)

      return if modified_plugins.empty?

      log.bold_warning "The following #{@context.hook_script_name} plugins " \
                       'have been added, changed, or had their configuration modified:'
      log.log

      modified_plugins.each do |signer|
        log.warning " * #{signer.hook_name} in #{signer.hook_path}"
      end

      log.log
      log.bold_warning 'You should verify the changes before continuing'
      log.log "For more information, see #{Overcommit::REPO_URL}#security"
      log.log
      log.partial 'Continue? (y/n) '

      unless (answer = @input.get) && answer.strip.downcase.start_with?('y')
        raise Overcommit::Exceptions::HookCancelled
      end

      modified_plugins.each(&:update_signature!)
    end
  end
end
