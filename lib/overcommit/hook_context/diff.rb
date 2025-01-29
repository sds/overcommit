# frozen_string_literal: true

require 'overcommit/git_repo'

module Overcommit::HookContext
  # Simulates a pre-commit context based on the diff with another git ref.
  #
  # This results in pre-commit hooks running against the changes between the current
  # and another ref, which is useful for automated CI scripts.
  class Diff < Base
    def modified_files
      @modified_files ||= Overcommit::GitRepo.modified_files(refs: @options[:diff])
    end

    def modified_lines_in_file(file)
      @modified_lines ||= {}
      @modified_lines[file] ||= Overcommit::GitRepo.extract_modified_lines(file,
                                                                           refs: @options[:diff])
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

    def initial_commit?
      @initial_commit ||= Overcommit::GitRepo.initial_commit?
    end
  end
end
