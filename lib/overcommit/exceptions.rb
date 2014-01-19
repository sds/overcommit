module Overcommit::Exceptions
  # Raised when a {Configuration} could not be loaded from a file.
  class ConfigurationError < StandardError; end

  # Raised when a hook could not be loaded by a {HookRunner}.
  class HookLoadError < StandardError; end

  # Raised when a {HookRunner} could not be loaded.
  class HookRunnerLoadError < StandardError; end

  # Raised when a installation target is not a valid git repository.
  class InvalidGitRepo < StandardError; end
end
