# frozen_string_literal: true

require 'tempfile'
require 'digest'
require 'shellwords'

module Overcommit::HookContext
  module Helpers
    # Hide unstaged changes without moving HEAD, rewriting the index, or using
    # the stash. Hooks retain the same file paths and can change the index.
    module HideUnstagedChanges
      def setup_environment
        store_modified_times
        save_unstaged_changes
        return unless @unstaged_patch

        apply_unstaged_changes(reverse: true)
        restore_modified_times
        @hook_contents = file_contents
      end

      # Returns whether the current git branch is empty (has no commits).
      def initial_commit?
        return @initial_commit unless @initial_commit.nil?

        @initial_commit = Overcommit::GitRepo.initial_commit?
      end

      def cleanup_environment
        return unless @unstaged_patch

        # Retain modification times for hook edits so file watchers see them.
        unchanged_files = file_contents.select { |file, contents| @hook_contents[file] == contents }
        apply_unstaged_changes
        restore_modified_times(unchanged_files.keys)
        File.unlink(@unstaged_patch)
        @unstaged_patch = nil
      end

      private

      def save_unstaged_changes
        result = Overcommit::Utils.execute(%w[
          git diff --binary --full-index --no-color --no-ext-diff --no-textconv
          --no-renames --ignore-submodules=all --src-prefix=a/ --dst-prefix=b/ --unified=3 --
        ])
        check_patch_result(result, Overcommit::Exceptions::HookSetupFailed)
        return if result.stdout.empty?

        # Tempfile.create returns a regular File: neither GC nor process exit
        # removes the recovery patch if setup, hooks, or cleanup are interrupted.
        file = Tempfile.create(['overcommit-unstaged-', '.patch'],
                               File.dirname(Overcommit::Utils.git_path('index')))
        begin
          file.binmode
          file.write(result.stdout)
          file.flush
          file.fsync
          @unstaged_patch = file.path
        ensure
          file.close
        end
      end

      def apply_unstaged_changes(reverse: false)
        command = %w[git apply --whitespace=nowarn]
        command << '--reverse' if reverse
        result = Overcommit::Utils.execute(command + ['--', @unstaged_patch])
        error = if reverse
                  Overcommit::Exceptions::HookSetupFailed
                else
                  Overcommit::Exceptions::HookCleanupFailed
                end
        check_patch_result(result, error)
      end

      def check_patch_result(result, error)
        return if result.success?

        recovery = if @unstaged_patch
                     "\nYour unstaged changes are preserved in #{@unstaged_patch}.\n" \
                       'Hook changes are preserved. Resolve any conflicts, then run' \
                       "#{Overcommit::OS.windows? ? ' in PowerShell' : ''}:\n" \
                       '  git apply --whitespace=nowarn -- ' \
                       "#{quoted_patch_path}\n"
                   end
        raise error,
              "Unable to restore or hide unstaged changes for #{hook_script_name} hooks:" \
              "\nSTDOUT:#{result.stdout}\nSTDERR:#{result.stderr}#{recovery}"
      end

      def quoted_patch_path
        if Overcommit::OS.windows?
          # Quote for PowerShell, including literal apostrophes in directory names.
          "'#{@unstaged_patch.gsub("'", "''")}'"
        else
          Shellwords.escape(@unstaged_patch)
        end
      end

      def store_modified_times
        @modified_times = {}
        files = modified_files + Overcommit::GitRepo.modified_files(staged: false)
        files.each do |file|
          next if Overcommit::Utils::FileUtils.symlink?(file)
          next unless File.file?(file)

          @modified_times[file] = File.mtime(file)
        end
      end

      def file_contents
        @modified_times.keys.each_with_object({}) do |file, contents|
          contents[file] = if Overcommit::Utils::FileUtils.symlink?(file)
                             [:symlink, Overcommit::Utils::FileUtils.readlink(file)]
                           elsif File.file?(file)
                             [:file, Digest::SHA256.file(file).hexdigest]
                           end
        end
      end

      def restore_modified_times(files = @modified_times.keys)
        files.each do |file|
          next if Overcommit::Utils::FileUtils.symlink?(file)
          next unless File.file?(file)

          File.utime(@modified_times.fetch(file), @modified_times.fetch(file), file)
        end
      end
    end
  end
end
