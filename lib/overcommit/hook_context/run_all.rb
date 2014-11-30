require 'set'

module Overcommit::HookContext
  # Simulates a pre-commit context pretending that all files have been changed.
  #
  # This results in pre-commit hooks running against the entire repository,
  # which is useful for automated CI scripts.
  class RunAll < Base
    EMPTY_SET = Set.new

    def modified_files
      all_files
    end

    # Return an empty set since in this context the user didn't actually touch
    # any lines.
    def modified_lines_in_file(_file)
      EMPTY_SET
    end

    def hook_class_name
      'PreCommit'
    end

    def hook_type_name
      'pre_commit'
    end

    def hook_script_name
      'pre-commit'
    end

    private

    def all_files
      @all_files ||= Overcommit::GitRepo.all_files
    end
  end
end
