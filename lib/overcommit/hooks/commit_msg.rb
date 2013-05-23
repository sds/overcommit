module Overcommit
  class CommitMessageHook < GitHook::BaseHook
    # No special behavior
  end

  Utils.register_hook(CommitMessageHook)
end
