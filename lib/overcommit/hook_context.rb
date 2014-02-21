# Utility module which manages the creation of {HookContext}s.
module Overcommit::HookContext
  def self.create(hook_type, config, args, input)
    hook_type_class = Overcommit::Utils.camel_case(hook_type)
    underscored_hook_type = Overcommit::Utils.snake_case(hook_type)

    require "overcommit/hook_context/#{underscored_hook_type}"

    Overcommit::HookContext.const_get(hook_type_class).new(config, args, input)
  rescue LoadError, NameError => error
    # Could happen when a symlink was created for a hook type Overcommit does
    # not yet support.
    raise Overcommit::Exceptions::HookContextLoadError,
          "Unable to load '#{hook_type}' hook context: '#{error}'",
          error.backtrace
  end
end
