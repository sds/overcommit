module Overcommit::Exceptions
  # Raised when a {Configuration} could not be loaded from a file.
  class ConfigurationError < StandardError; end

  # Raised when the Overcommit configuration file signature has changed.
  class ConfigurationSignatureChanged < StandardError; end

  # Raised when trying to read/write to/from the local repo git config fails.
  class GitConfigError < StandardError; end

  # Raised when there was a problem reading submodule information for a repo.
  class GitSubmoduleError < StandardError; end

  # Raised when there was a problem reading git revision information with `rev-list`.
  class GitRevListError < StandardError; end

  # Raised when a {HookContext} is unable to setup the environment before a run.
  class HookSetupFailed < StandardError; end

  # Raised when a {HookContext} is unable to clean the environment after a run.
  class HookCleanupFailed < StandardError; end

  # Raised when a hook run was cancelled by the user.
  class HookCancelled < StandardError; end

  # Raised when a hook could not be loaded by a {HookRunner}.
  class HookLoadError < StandardError; end

  # Raised when a {HookRunner} could not be loaded.
  class HookContextLoadError < StandardError; end

  # Raised when a pipe character is used in the `execute` helper, as this was
  # likely used in error.
  class InvalidCommandArgs < StandardError; end

  # Raised when an installation target is not a valid git repository.
  class InvalidGitRepo < StandardError; end

  # Raised when a hook was defined incorrectly.
  class InvalidHookDefinition < StandardError; end

  # Raised when one or more hook plugin signatures have changed.
  class InvalidHookSignature < StandardError; end

  # Raised when there is a problem processing output into {Hook::Messages}s.
  class MessageProcessingError < StandardError; end

  # Raised when an installation target already contains non-Overcommit hooks.
  class PreExistingHooks < StandardError; end
end
