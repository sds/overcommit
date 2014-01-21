module Overcommit::Hook::CommitMsg
  # Functionality common to all commit-msg hooks.
  class Base < Overcommit::Hook::Base
    def commit_message
      @hook_runner.commit_message
    end
  end
end
