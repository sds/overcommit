require 'fileutils'
require 'set'

module Overcommit::HookContext
  # Contains helpers related to contextual information used by pre-commit hooks.
  #
  # This includes staged files, which lines of those files have been modified,
  # etc.
  class PreCommit < Base
    # Stash unstaged contents of files so hooks don't see changes that aren't
    # about to be committed.
    def setup_environment
      store_modified_times
      store_merge_state
      store_cherry_pick_state

      if !initial_commit? && any_changes?
        @changes_stashed = true
        `git stash save --keep-index --quiet #{<<-MSG}`
          "Overcommit: Stash of repo state before hook run at #{Time.now}"
        MSG
      end

      # While running the hooks make it appear as if nothing changed
      restore_modified_times
    end

    # Restore unstaged changes and reset file modification times so it appears
    # as if nothing ever changed.
    def cleanup_environment
      unless initial_commit?
        `git reset --hard &> /dev/null` # Ensure working tree is clean before popping stash
      end

      if @changes_stashed
        `git stash pop --index --quiet`
      end

      restore_merge_state
      restore_cherry_pick_state
      restore_modified_times
    end

    # Get a list of added, copied, or modified files that have been staged.
    # Renames and deletions are ignored, since there should be nothing to check.
    def modified_files
      @modified_files ||=
        `git diff --cached --name-only -z --diff-filter=ACM --ignore-submodules=all`.
          split("\0").
          map { |relative_file| File.expand_path(relative_file) }
    end

    # Returns the set of line numbers corresponding to the lines that were
    # changed in a specified file.
    def modified_lines(file)
      @modified_lines ||= {}
      @modified_lines[file] ||= extract_modified_lines(file)
    end

  private

    # Returns whether there are any changes to the working tree, staged or
    # otherwise.
    def any_changes?
      modified_files = `git status -z --untracked-files=no`.
        split("\0").
        map { |line| line.gsub(/[^\s]+\s+(.+)/, '\\1') }

      modified_files.any?
    end

    # Returns whether the current git branch is empty (has no commits).
    def initial_commit?
      return @initial_commit unless @initial_commit.nil?
      @initial_commit = !Overcommit::Utils.execute(%w[git rev-parse HEAD]).success?
    end

    DIFF_HUNK_REGEX = /
      ^@@\s
      [^\s]+\s           # Ignore old file range
      \+(\d+)(?:,(\d+))? # Extract range of hunk containing start line and number of lines
      \s@@.*$
    /x

    def extract_modified_lines(staged_file)
      lines = Set.new

      `git diff --no-ext-diff --cached -U0 -- #{staged_file}`.
        scan(DIFF_HUNK_REGEX) do |start_line, lines_added|

        lines_added = (lines_added || 1).to_i # When blank, one line was added
        cur_line = start_line.to_i

        lines_added.times do
          lines.add cur_line
          cur_line += 1
        end
      end

      lines
    end

    def store_merge_state
      merge_head = `git rev-parse MERGE_HEAD 2> /dev/null`.chomp

      # Store the merge state if we're in the middle of resolving a merge
      # conflict. This is necessary since stashing removes the merge state.
      if merge_head != 'MERGE_HEAD'
        @merge_head = merge_head

        merge_msg_file = File.expand_path('.git/MERGE_MSG', Overcommit::Utils.repo_root)
        @merge_msg = File.open(merge_msg_file).read if File.exist?(merge_msg_file)
      end
    end

    def store_cherry_pick_state
      cherry_head = `git rev-parse CHERRY_PICK_HEAD 2> /dev/null`.chomp

      # Store the merge state if we're in the middle of resolving a merge
      # conflict. This is necessary since stashing removes the merge state.
      if cherry_head != 'CHERRY_PICK_HEAD'
        @cherry_head = cherry_head
      end
    end

    def restore_merge_state
      if @merge_head
        FileUtils.touch(File.expand_path('.git/MERGE_MODE', Overcommit::Utils.repo_root))

        File.open(File.expand_path('.git/MERGE_HEAD', Overcommit::Utils.repo_root), 'w') do |f|
          f.write("#{@merge_head}\n")
        end
        @merge_head = nil
      end

      if @merge_msg
        File.open(File.expand_path('.git/MERGE_MSG', Overcommit::Utils.repo_root), 'w') do |f|
          f.write("#{@merge_msg}\n")
        end
        @merge_msg = nil
      end
    end

    def restore_cherry_pick_state
      if @cherry_head
        File.open(File.expand_path('.git/CHERRY_PICK_HEAD',
                                   Overcommit::Utils.repo_root), 'w') do |f|
          f.write("#{@cherry_head}\n")
        end
        @cherry_head = nil
      end
    end

    def store_modified_times
      @modified_times = {}

      modified_files.each do |file|
        @modified_times[file] = File.mtime(file)
      end
    end

    # Stores the modification times for all modified files to make it appear like
    # they never changed.
    #
    # This prevents editors from complaining about files changing when we stash
    # changes before running the hooks.
    def restore_modified_times
      modified_files.each do |file|
        time = @modified_times[file]
        File.utime(time, time, file)
      end
    end
  end
end
