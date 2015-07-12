module Overcommit::HookLoader
  # Responsible for loading hooks that are defined entirely in Overcommit
  # configuration files.
  class AdHocHookLoader < Base
    def load_hooks
      @config.enabled_ad_hoc_hooks(@context).map do |hook_name|
        create_ad_hoc_hook(hook_name)
      end
    end

    private

    def create_ad_hoc_hook(hook_name)
      hook_module = Overcommit::Hook.const_get(@context.hook_class_name)
      hook_base = hook_module.const_get('Base')

      # Implement a simple class that executes the command and returns pass/fail
      # based on the exit status
      hook_class = Class.new(hook_base) do
        def run # rubocop:disable Lint/NestedMethodDefinition
          result = @context.execute_hook(command)

          if result.success?
            :pass
          else
            [:fail, result.stdout + result.stderr]
          end
        end
      end

      hook_module.const_set(hook_name, hook_class).new(@config, @context)
    rescue LoadError, NameError => error
      raise Overcommit::Exceptions::HookLoadError,
            "Unable to load hook '#{hook_name}': #{error}",
            error.backtrace
    end
  end
end
