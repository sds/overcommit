require 'set'

module Overcommit::HookContext
  # Simulates a pre-commit context pretending that all files have been changed.
  #
  # This results in pre-commit hooks running against the entire repository,
  # which is useful for automated CI scripts.
  class RunAll < Base
    def modified_files
      @modified_files ||= all_files
    end

    # Returns all lines in the file since in this context the entire repo is
    # being scrutinized.
    #
    # @param file [String]
    # @return [Set]
    def modified_lines_in_file(file)
      @modified_lines_in_file ||= {}
      @modified_lines_in_file[file] ||= Set.new(1..count_lines(file))
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
      return @initial_commit unless @initial_commit.nil?
      @initial_commit = Overcommit::GitRepo.initial_commit?
    end

    private

    def count_lines(file)
      File.foreach(file).count
    end
  end
end
