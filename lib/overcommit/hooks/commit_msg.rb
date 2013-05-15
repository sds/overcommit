module Overcommit
  class CommitMessageHook < GitHook::BaseHook
    # No special behavior
  end

  GitHook.register_hook(CommitMessageHook)
end
