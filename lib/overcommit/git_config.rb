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
