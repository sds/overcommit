# Utility module which manages the creation of {HookContext}s.
module Overcommit::HookContext
  def self.create(hook_type, config, args, input)
    require "overcommit/hook_context/#{hook_type.gsub('-', '_')}"

    Overcommit::HookContext.const_get(hook_type_to_class_name(hook_type))
                           .new(config, args, input)
  rescue LoadError, NameError => error
    # Could happen when a symlink was created for a hook type Overcommit does
    # not yet support.
    raise Overcommit::Exceptions::HookContextLoadError,
          "Unable to load '#{hook_type}' hook context: '#{error}'",
          error.backtrace
  end

private

  def self.hook_type_to_class_name(hook_type)
    hook_type.split('-').map { |s| s.capitalize }.join
  end
end
