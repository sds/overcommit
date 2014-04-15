module Overcommit::HookLoader
  # Responsible for loading hooks that are specific to the repository Overcommit
  # is running in.
  class PluginHookLoader < Base
    def load_hooks
      directory = File.join(@config.plugin_directory, @context.hook_type_name)

      Dir[File.join(directory, '*.rb')].sort.map do |plugin|
        require plugin

        hook_name = Overcommit::Utils.camel_case(File.basename(plugin, '.rb'))
        create_hook(hook_name)
      end
    end
  end
end
