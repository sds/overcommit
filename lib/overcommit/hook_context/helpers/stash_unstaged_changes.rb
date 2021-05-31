# frozen_string_literal: true

module Overcommit::HookContext
  module Helpers
    # This module contains behavior for stashing unstaged changes before hooks are ran and restoring
    # them afterwards
    module StashUnstagedChanges
      # Stash unstaged contents of files so hooks don't see changes that aren't
      # about to be committed.
      def setup_environment
        store_modified_times
        Overcommit::GitRepo.store_merge_state
        Overcommit::GitRepo.store_cherry_pick_state

        # Don't attempt to stash changes if all changes are staged, as this
        # prevents us from modifying files at all, which plays better with
        # editors/tools which watch for file changes.
        if !initial_commit? && unstaged_changes?
          stash_changes

          # While running hooks make it appear as if nothing changed
          restore_modified_times
        end
      end

      # Returns whether the current git branch is empty (has no commits).
      def initial_commit?
        return @initial_commit unless @initial_commit.nil?
        @initial_commit = Overcommit::GitRepo.initial_commit?
      end

      # Restore unstaged changes and reset file modification times so it appears
      # as if nothing ever changed.
      #
      # We want to restore the modification times for each of the files after
      # every step to ensure as little time as possible has passed while the
      # modification time on the file was newer. This helps us play more nicely
      # with file watchers.
      def cleanup_environment
        if @changes_stashed
          clear_working_tree
          restore_working_tree
          restore_modified_times
        end

        Overcommit::GitRepo.restore_merge_state
        Overcommit::GitRepo.restore_cherry_pick_state
      end

      private

      # Stores the modification times for all modified files to make it appear like
      # they never changed.
      #
      # This prevents (some) editors from complaining about files changing when we
      # stash changes before running the hooks.
      def store_modified_times
        @modified_times = {}

        staged_files = modified_files
        unstaged_files = Overcommit::GitRepo.modified_files(staged: false)

        (staged_files + unstaged_files).each do |file|
          next if Overcommit::Utils.broken_symlink?(file)
          next unless File.exist?(file) # Ignore renamed files (old file no longer exists)
          @modified_times[file] = File.mtime(file)
        end
      end

      # Returns whether there are any changes to tracked files which have not yet
      # been staged.
      def unstaged_changes?
        result = Overcommit::Utils.execute(%w[git --no-pager diff --quiet])
        !result.success?
      end

      def stash_changes
        @stash_attempted = true

        stash_message = "Overcommit: Stash of repo state before hook run at #{Time.now}"
        result = Overcommit::Utils.with_environment('GIT_LITERAL_PATHSPECS' => '0') do
          Overcommit::Utils.execute(
            %w[git -c commit.gpgsign=false stash save --keep-index --quiet] + [stash_message]
          )
        end

        unless result.success?
          # Failure to stash in this case is likely due to a configuration
          # issue (e.g. author/email not set or GPG signing key incorrect)
          raise Overcommit::Exceptions::HookSetupFailed,
                "Unable to setup environment for #{hook_script_name} hook run:" \
                "\nSTDOUT:#{result.stdout}\nSTDERR:#{result.stderr}"
        end

        @changes_stashed = `git stash list -1`.include?(stash_message)
      end

      # Restores the file modification times for all modified files to make it
      # appear like they never changed.
      def restore_modified_times
        @modified_times.each do |file, time|
          next if Overcommit::Utils.broken_symlink?(file)
          next unless File.exist?(file)
          File.utime(time, time, file)
        end
      end

      # Clears the working tree so that the stash can be applied.
      def clear_working_tree
        removed_submodules = Overcommit::GitRepo.staged_submodule_removals

        result = Overcommit::Utils.execute(%w[git reset --hard])
        unless result.success?
          raise Overcommit::Exceptions::HookCleanupFailed,
                "Unable to cleanup working tree after #{hook_script_name} hooks run:" \
                "\nSTDOUT:#{result.stdout}\nSTDERR:#{result.stderr}"
        end

        # Hard-resetting a staged submodule removal results in the index being
        # reset but the submodule being restored as an empty directory. This empty
        # directory prevents us from stashing on a subsequent run if a hook fails.
        #
        # Work around this by removing these empty submodule directories as there
        # doesn't appear any reason to keep them around.
        removed_submodules.each do |submodule|
          FileUtils.rmdir(submodule.path)
        end
      end

      # Applies the stash to the working tree to restore the user's state.
      def restore_working_tree
        result = Overcommit::Utils.execute(%w[git stash pop --index])
        unless result.success?
          raise Overcommit::Exceptions::HookCleanupFailed,
                "Unable to restore working tree after #{hook_script_name} hooks run:" \
                "\nSTDOUT:#{result.stdout}\nSTDERR:#{result.stderr}"
        end
      end
    end
  end
end
