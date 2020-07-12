# frozen_string_literal: true

module Overcommit::Exceptions
  # Base error class.
  class Error < StandardError; end

  # Raised when a {Configuration} could not be loaded from a file.
  class ConfigurationError < Error; end

  # Raised when the Overcommit configuration file signature has changed.
  class ConfigurationSignatureChanged < Error; end

  # Raised when trying to read/write to/from the local repo git config fails.
  class GitConfigError < Error; end

  # Raised when there was a problem reading submodule information for a repo.
  class GitSubmoduleError < Error; end

  # Raised when there was a problem reading git revision information with `rev-list`.
  class GitRevListError < Error; end

  # Raised when a {HookContext} is unable to setup the environment before a run.
  class HookSetupFailed < Error; end

  # Raised when a {HookContext} is unable to clean the environment after a run.
  class HookCleanupFailed < Error; end

  # Raised when a hook run was cancelled by the user.
  class HookCancelled < Error; end

  # Raised when a hook could not be loaded by a {HookRunner}.
  class HookLoadError < Error; end

  # Raised when a {HookRunner} could not be loaded.
  class HookContextLoadError < Error; end

  # Raised when a pipe character is used in the `execute` helper, as this was
  # likely used in error.
  class InvalidCommandArgs < Error; end

  # Raised when an installation target is not a valid git repository.
  class InvalidGitRepo < Error; end

  # Raised when a hook was defined incorrectly.
  class InvalidHookDefinition < Error; end

  # Raised when one or more hook plugin signatures have changed.
  class InvalidHookSignature < Error; end

  # Raised when there is a problem processing output into {Hook::Messages}s.
  class MessageProcessingError < Error; end

  # Raised when an installation target already contains non-Overcommit hooks.
  class PreExistingHooks < Error; end
end
