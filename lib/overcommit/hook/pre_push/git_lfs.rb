module Overcommit::Hook::PrePush
  # Replaces the pre-push hook installed by `git lfs install` that is then moved aside by
  # `overcommit --install`
  #
  # Enable this hook in .overcommit.yml like so:
  #
  #  PrePush:
  #    GitLfs:
  #      enabled: true
  #      command: ['git', 'lfs', 'pre-push']
  #
  # @see https://github.com/github/git-lfs
  class GitLfs < Base
    # Overcommit expects you to override this method which will be called
    # everytime your pre-commit hook is run.
    def run
      # Create two arrays to hold our error and warning messages.
      error_lines = []
      warning_lines = []

      # Check if git-lfs executable exists
      path_to_git_lfs = `command -v git-lfs`.strip
      error_lines << "This repository is configured for Git LFS but 'git-lfs' was not found "\
                     "on your path. If you no longer wish to use Git LFS, disable GitLfs in "\
                     ".overcommit.yml." unless File.exist?(path_to_git_lfs)

      result = execute(command, input: pushed_refs)
      error_lines << "'#{command}' returned non-zero exit status: #{result.status}" unless
        result.success?

      # Overcommit expects 1 of the 3 as return values, `:fail`, `:warn` or `:pass`.
      # If the hook returns `:fail`, the commit will be aborted with our message
      # containing the errors.
      return :fail, error_lines.join("\n") if error_lines.any?

      :pass
    end

    def command
      super + ["#{remote_name}", "#{remote_url}"]
    end
  end
end
