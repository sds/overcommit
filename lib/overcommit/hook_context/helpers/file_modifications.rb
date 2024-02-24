# frozen_string_literal: true

module Overcommit::HookContext
  module Helpers
    # This module contains methods for determining what files were changed and on what unique line
    # numbers did the change occur.
    module FileModifications
      # Returns whether this hook run was triggered by `git commit --amend`
      def amendment?
        return @amendment unless @amendment.nil?

        cmd = Overcommit::Utils.parent_command
        return unless cmd

        amend_pattern = /commit(\s.*)?\s--amend/

        # Since the ps command can return invalid byte sequences for commands
        # containing unicode characters, we replace the offending characters,
        # since the pattern we're looking for will consist of ASCII characters
        unless cmd.valid_encoding?
          cmd = Overcommit::Utils.
            parent_command.
            encode('UTF-16be', invalid: :replace, replace: '?').
            encode('UTF-8')
        end

        # True if the command is a commit with the --amend flag
        return @amendment if @amendment = cmd.match?(amend_pattern)

        # Check for git aliases that call `commit --amend`
        return @amendment if @amendment = command_is_amend_alias?(cmd, amend_pattern)

        @amendment
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

      private

      def command_is_amend_alias?(cmd, amend_pattern)
        `git config --get-regexp "^alias"`.split("\n").each do |alias_def|
          alias_map = alias_def.match /alias\.(?<to>[-\w]+)\s+(?<from>.+)/
          next unless alias_map

          alias_from_match = alias_map[:from].match? amend_pattern
          alias_to_match = cmd.match? /git(\.exe)?\s+#{alias_map[:to]}/

          # True if the command uses a git alias for `commit --amend`
          return true if @amendment = alias_from_match && alias_to_match
        end
        false
      end
    end
  end
end
