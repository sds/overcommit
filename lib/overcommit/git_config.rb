# frozen_string_literal: true

require 'overcommit/utils'

module Overcommit
  # Get configuration options from git
  module GitConfig
    module_function

    def comment_character
      char = `git config --get core.commentchar`.chomp
      char = '#' if char == ''
      char
    end

    # Git does not pass cleanup options to commit-msg hooks. Use the invoking
    # command's override, then configuration, and Git's documented editor marker.
    def commit_cleanup_mode
      command = Overcommit::Utils.parent_command.to_s.scrub
      modes = command.scan(
        /(?:\A|\s)["']?--cleanup
         (?:=["']?|["']?\s+["']?)
         (strip|whitespace|verbatim|scissors|default)["']?(?=\s|\z)/x
      )
      mode = modes.last&.first || `git config --get commit.cleanup`.chomp
      Overcommit::Utils.log&.debug("Commit cleanup mode #{mode.inspect} from #{command.inspect}")
      if mode.empty? || mode == 'default'
        ENV['GIT_EDITOR'] == ':' ? 'whitespace' : 'strip'
      else
        mode
      end
    end

    def hooks_path
      path = `git config --get core.hooksPath`.chomp
      return File.join(Overcommit::Utils.git_dir, 'hooks') if path.empty?

      File.expand_path(path, Dir.pwd)
    end

    # Config file option for storing hook signatures: the per-worktree file
    # when extensions.worktreeConfig is on, so worktrees with different
    # configurations do not overwrite each other's signatures.
    def signature_scope
      enabled = `git config --bool --get extensions.worktreeConfig`.chomp
      enabled == 'true' ? '--worktree' : '--local'
    end
  end
end
