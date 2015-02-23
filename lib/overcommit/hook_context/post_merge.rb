module Overcommit::HookContext
  # Contains helpers related to contextual information used by post-merge
  # hooks.
  class PostMerge < Base
    attr_accessor :args
    # Get a list of files that were added, copied, or modified in the merge
    # commit. Renames and deletions are ignored, since there should be nothing
    # to check.
    def modified_files
      staged = squash?
      refs = 'HEAD^ HEAD' if merge_commit?
      @modified_files ||= Overcommit::GitRepo.modified_files(staged: staged, refs: refs)
    end

    # Returns the set of line numbers corresponding to the lines that were
    # changed in a specified file.
    def modified_lines_in_file(file)
      staged = squash?
      refs = 'HEAD^ HEAD' if merge_commit?
      @modified_lines ||= {}
      @modified_lines[file] ||=
        Overcommit::GitRepo.extract_modified_lines(file, staged: staged, refs: refs)
    end

    # Returns whether this merge was made using --squash
    def squash?
      @args[0].to_i == 1
    end

    # Returns whether this merge was made without --squash
    def merge_commit?
      !squash?
    end
  end
end
