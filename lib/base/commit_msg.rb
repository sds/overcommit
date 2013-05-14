require 'rubygems'

module Causes
  class CommitMessageHook < GitHook::BaseHook
    # No special behavior
  end

  GitHook.register_hook(CommitMessageHook)
end
