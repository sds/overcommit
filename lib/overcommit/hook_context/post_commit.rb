module Overcommit::HookContext
  # Contains helpers related to contextual information used by post-commit
  # hooks.
  class PostCommit < Base
    # Get a list of files that were added, copied, or modified in the last
    # commit. Renames and deletions are ignored, since there should be nothing
    # to check.
    def modified_files
      subcmd = 'show --format=%n'
      @modified_files ||= Overcommit::GitRepo.modified_files(subcmd: subcmd)
    end

    # Returns the set of line numbers corresponding to the lines that were
    # changed in a specified file.
    def modified_lines_in_file(file)
      subcmd = 'show --format=%n'
      @modified_lines ||= {}
      @modified_lines[file] ||=
        Overcommit::GitRepo.extract_modified_lines(file, subcmd: subcmd)
    end

    # Returns whether the commit that triggered this hook is the first commit on
    # the branch.
    #
    # @return [true,false]
    def initial_commit?
      return @initial_commit unless @initial_commit.nil?
      @initial_commit = !Overcommit::Utils.execute(%w[git rev-parse HEAD~]).success?
    end
  end
end
