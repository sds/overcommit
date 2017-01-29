require 'fileutils'
require 'set'

module Overcommit::HookContext
  # Contains helpers related to contextual information used by pre-commit hooks.
  #
  # This includes staged files, which lines of those files have been modified,
  # etc. It is also responsible for saving/restoring the state of the repo so
  # hooks only inspect staged changes.
  class PreCommit < Base # rubocop:disable ClassLength
    # Returns whether this hook run was triggered by `git commit --amend`
    def amendment?
      return @amendment unless @amendment.nil?

      cmd = Overcommit::Utils.parent_command
      amend_pattern = 'commit(\s.*)?\s--amend(\s|$)'

      # Since the ps command can return invalid byte sequences for commands
      # containing unicode characters, we replace the offending characters,
      # since the pattern we're looking for will consist of ASCII characters
      unless cmd.valid_encoding?
        cmd.encode!('UTF-16be', invalid: :replace, replace: '?').encode!('UTF-8')
      end

      return @amendment if
        # True if the command is a commit with the --amend flag
        @amendment = !(/\s#{amend_pattern}/ =~ cmd).nil?

      # Check for git aliases that call `commit --amend`
      `git config --get-regexp "^alias\\." "#{amend_pattern}"`.
        scan(/alias\.([-\w]+)/). # Extract the alias
        each do |match|
          return @amendment if
            # True if the command uses a git alias for `commit --amend`
            @amendment = !(/git(\.exe)?\s+#{match[0]}/ =~ cmd).nil?
        end

      @amendment
    end

    # Stash unstaged contents of files so hooks don't see changes that aren't
    # about to be committed.
    def setup_environment
      store_modified_times
      Overcommit::GitRepo.store_merge_state
      Overcommit::GitRepo.store_cherry_pick_state

      if !initial_commit? && any_changes?
        @stash_attempted = true

        stash_message = "Overcommit: Stash of repo state before hook run at #{Time.now}"
        result = Overcommit::Utils.execute(
          %w[git -c commit.gpgsign=false stash save --keep-index --quiet] + [stash_message]
        )

        unless result.success?
          # Failure to stash in this case is likely due to a configuration
          # issue (e.g. author/email not set or GPG signing key incorrect)
          raise Overcommit::Exceptions::HookSetupFailed,
                "Unable to setup environment for #{hook_script_name} hook run:" \
                "\nSTDOUT:#{result.stdout}\nSTDERR:#{result.stderr}"
        end

        @changes_stashed = `git stash list -1`.include?(stash_message)
      end

      # While running the hooks make it appear as if nothing changed
      restore_modified_times
    end

    # Restore unstaged changes and reset file modification times so it appears
    # as if nothing ever changed.
    #
    # We want to restore the modification times for each of the files after
    # every step to ensure as little time as possible has passed while the
    # modification time on the file was newer. This helps us play more nicely
    # with file watchers.
    def cleanup_environment
      unless initial_commit? || (@stash_attempted && !@changes_stashed)
        clear_working_tree # Ensure working tree is clean before restoring it
        restore_modified_times
      end

      if @changes_stashed
        restore_working_tree
        restore_modified_times
      end

      Overcommit::GitRepo.restore_merge_state
      Overcommit::GitRepo.restore_cherry_pick_state
      restore_modified_times
    end

    # Get a list of added, copied, or modified files that have been staged.
    # Renames and deletions are ignored, since there should be nothing to check.
    def modified_files
      unless @modified_files
        currently_staged = Overcommit::GitRepo.modified_files(staged: true)
        @modified_files = currently_staged

        # Include files modified in last commit if amending
        if amendment?
          subcmd = 'show --format=%n'
          previously_modified = Overcommit::GitRepo.modified_files(subcmd: subcmd)
          @modified_files |= filter_modified_files(previously_modified)
        end
      end
      @modified_files
    end

    # Returns the set of line numbers corresponding to the lines that were
    # changed in a specified file.
    def modified_lines_in_file(file)
      @modified_lines ||= {}
      unless @modified_lines[file]
        @modified_lines[file] =
          Overcommit::GitRepo.extract_modified_lines(file, staged: true)

        # Include lines modified in last commit if amending
        if amendment?
          subcmd = 'show --format=%n'
          @modified_lines[file] +=
            Overcommit::GitRepo.extract_modified_lines(file, subcmd: subcmd)
        end
      end
      @modified_lines[file]
    end

    # Returns whether the current git branch is empty (has no commits).
    def initial_commit?
      return @initial_commit unless @initial_commit.nil?
      @initial_commit = Overcommit::GitRepo.initial_commit?
    end

    private

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

    # Restores the file modification times for all modified files to make it
    # appear like they never changed.
    def restore_modified_times
      @modified_times.each do |file, time|
        next if Overcommit::Utils.broken_symlink?(file)
        next unless File.exist?(file)
        File.utime(time, time, file)
      end
    end
  end
end
