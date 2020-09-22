# frozen_string_literal: true

require 'fileutils'
require 'set'
require_relative 'helpers/stash_unstaged_changes'
require_relative 'helpers/file_modifications'

module Overcommit::HookContext
  # Contains helpers related to contextual information used by pre-commit hooks.
  #
  # This includes staged files, which lines of those files have been modified,
  # etc. It is also responsible for saving/restoring the state of the repo so
  # hooks only inspect staged changes.
  class PreCommit < Base
    include Overcommit::HookContext::Helpers::StashUnstagedChanges
    include Overcommit::HookContext::Helpers::FileModifications
  end
end
