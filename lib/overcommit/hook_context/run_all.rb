require 'fileutils'
require 'set'

module Overcommit::HookContext
  # Contains helpers related to contextual information used by pre-commit hooks.
  #
  # This includes staged files, which lines of those files have been modified,
  # etc. It is also responsible for saving/restoring the state of the repo so
  # hooks only inspect staged changes.
  class RunAll < Base
    # Get a list of added, copied, or modified files that have been staged.
    # Renames and deletions are ignored, since there should be nothing to check.
    def modified_files
      all_files
    end

    # Returns the camel-cased type of this hook (e.g. PreCommit)
    def hook_class_name
      'PreCommit'
    end

    # Returns the snake-cased type of this hook (e.g. pre_commit)
    def hook_type_name
      'pre_commit'
    end

    # Returns the actual name of the hook script being run (e.g. pre-commit).
    def hook_script_name
      'pre-commit'
    end

    private

    def all_files
      @all_files ||= Overcommit::GitRepo.all_files
    end
  end
end
