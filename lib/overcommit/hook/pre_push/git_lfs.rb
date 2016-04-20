module Overcommit::Hook::PrePush
  # Replaces the pre-push hook installed by `git lfs install` that is then moved aside by
  # `overcommit --install`
  #
  # @see https://github.com/github/git-lfs
  class GitLfs < Base
    def run
      result = execute(command, args: ['pre-push', remote_name, remote_url], input: @context.input_string)
      return :fail, result.stdout + result.stderr unless result.success?
      :pass
    end
  end
end
