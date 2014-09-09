require 'fileutils'
require 'set'

module Overcommit::HookContext
  # Contains helpers related to contextual information used by pre-commit hooks.
  #
  # This includes staged files, which lines of those files have been modified,
  # etc. It is also responsible for saving/restoring the state of the repo so
  # hooks only inspect staged changes.
  class PreCommit < Base
    # Stash unstaged contents of files so hooks don't see changes that aren't
    # about to be committed.
    def setup_environment
      store_modified_times
      Overcommit::GitRepo.store_merge_state
      Overcommit::GitRepo.store_cherry_pick_state

      if !initial_commit? && any_changes?
        @stash_attempted = true

        result = Overcommit::Utils.execute(
          %w[git stash save --keep-index --quiet] +
          ["Overcommit: Stash of repo state before hook run at #{Time.now}"]
        )

        unless result.success?
          # Failure to stash in this case is likely due to a configuration
          # issue (e.g. author/email not set or GPG signing key incorrect)
          raise Overcommit::Exceptions::HookSetupFailed,
                "Unable to setup environment for #{hook_script_name} hook run:" \
                "\nSTDOUT:#{result.stdout}\nSTDERR:#{result.stderr}"
        end

        @changes_stashed = true
      end

      # While running the hooks make it appear as if nothing changed
      restore_modified_times
    end

    # Restore unstaged changes and reset file modification times so it appears
    # as if nothing ever changed.
    def cleanup_environment
      unless initial_commit? || (@stash_attempted && !@changes_stashed)
        clear_working_tree # Ensure working tree is clean before restoring it
      end

      if @changes_stashed
        restore_working_tree
      end

      Overcommit::GitRepo.restore_merge_state
      Overcommit::GitRepo.restore_cherry_pick_state
      restore_modified_times
    end

    # Get a list of added, copied, or modified files that have been staged.
    # Renames and deletions are ignored, since there should be nothing to check.
    def modified_files
      @modified_files ||= Overcommit::GitRepo.modified_files(:staged => true)
    end

    # Returns the set of line numbers corresponding to the lines that were
    # changed in a specified file.
    def modified_lines(file)
      @modified_lines ||= {}
      @modified_lines[file] ||= Overcommit::GitRepo.extract_modified_lines(file, :staged => true)
    end

    private

    # Clears the working tree so that the stash can be applied.
    def clear_working_tree
      result = Overcommit::Utils.execute(%w[git reset --hard])
      unless result.success?
        raise Overcommit::Exceptions::HookCleanupFailed,
              "Unable to cleanup working tree after #{hook_script_name} hooks run:" \
              "\nSTDOUT:#{result.stdout}\nSTDERR:#{result.stderr}"
      end
    end

    # Applies the stash to the working tree to restore the user's state.
    def restore_working_tree
      result = Overcommit::Utils.execute(%w[git stash pop --index --quiet])
      unless result.success?
        raise Overcommit::Exceptions::HookCleanupFailed,
              "Unable to restore working tree after #{hook_script_name} hooks run:" \
              "\nSTDOUT:#{result.stdout}\nSTDERR:#{result.stderr}"
      end
    end

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
      @initial_commit = Overcommit::GitRepo.initial_commit?
    end

    # Stores the modification times for all modified files to make it appear like
    # they never changed.
    #
    # This prevents (some) editors from complaining about files changing when we
    # stash changes before running the hooks.
    def store_modified_times
      @modified_times = {}

      modified_files.each do |file|
        next if Overcommit::Utils.broken_symlink?(file)
        @modified_times[file] = File.mtime(file)
      end
    end

    # Restores the file modification times for all modified files to make it
    # appear like they never changed.
    def restore_modified_times
      modified_files.each do |file|
        next if Overcommit::Utils.broken_symlink?(file)
        time = @modified_times[file]
        File.utime(time, time, file)
      end
    end
  end
end
