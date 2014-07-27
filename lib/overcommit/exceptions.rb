module Overcommit::Exceptions
  # Raised when a {Configuration} could not be loaded from a file.
  class ConfigurationError < StandardError; end

  # Raised when trying to read/write to/from the local repo git config fails.
  class GitConfigError < StandardError; end

  # Raised when a {HookContext} is unable to setup the environment before a run.
  class HookSetupFailed < StandardError; end

  # Raised when a hook run was cancelled by the user.
  class HookCancelled < StandardError; end

  # Raised when a hook could not be loaded by a {HookRunner}.
  class HookLoadError < StandardError; end

  # Raised when a {HookRunner} could not be loaded.
  class HookContextLoadError < StandardError; end

  # Raised when an installation target is not a valid git repository.
  class InvalidGitRepo < StandardError; end

  # Raised when an installation target already contains non-Overcommit hooks.
  class PreExistingHooks < StandardError; end
end
