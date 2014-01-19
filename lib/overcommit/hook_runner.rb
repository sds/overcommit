# Utility module which manages the creation of {HookRunner}s.
module Overcommit::HookRunner
  # Creates a {HookRunner} for the given hook type (e.g. 'pre-commit',
  # 'commit-msg', etc.)
  def self.create(hook_type, config)
    require "overcommit/hook_runner/#{hook_type.gsub('-', '_')}"

    Overcommit::HookRunner.const_get(hook_type_to_class_name(hook_type)).
                           new(config)
  rescue LoadError, NameError => error
    # Could happen when a symlink was created for a hook type Overcommit does
    # not yet support.
    raise Overcommit::Exceptions::HookRunnerLoadError,
          "Unable to load '#{hook_type}' hook runner: '#{error}'",
          error.backtrace
  end

private

  # TODO: move into generic utility method
  # Returns the CamelCase form from the specified hook type,
  # e.g. 'pre-commit' -> 'PreCommit'.
  def self.hook_type_to_class_name(hook_type)
    hook_type.split('-').map { |s| s.capitalize }.join
  end
end
