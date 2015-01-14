module Overcommit::HookContext
  # Contains helpers related to contextual information used by post-commit
  # hooks.
  class PostCommit < Base
    # Get a list of files that were added, copied, or modified in the last
    # commit. Renames and deletions are ignored, since there should be nothing
    # to check.
    def modified_files_last_commit
      @modified_files_last_commit ||= Overcommit::GitRepo.modified_files_last_commit
    end

    # Returns the set of line numbers corresponding to the lines that were
    # changed in a specified file.
    def modified_lines_in_file_last_commit(file)
      @modified_lines_last_commit ||= {}
      @modified_lines_last_commit[file] ||=
        Overcommit::GitRepo.extract_modified_lines_last_commit(file)
    end
  end
end
