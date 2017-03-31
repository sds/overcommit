module Overcommit::Hook::PrePush
  # Invokes Git LFS command that uploads files tracked by Git LFS to the LFS storage
  #
  # @see https://git-lfs.github.com/
  class GitLfs < Base
    def run
      unless in_path?('git-lfs')
        return :warn, 'This repository is configured for Git LFS but \'git-lfs\' ' \
        "was not found on your path.\nIf you no longer wish to use Git LFS, " \
        'disable this hook by removing or setting \'enabled: false\' for GitLFS ' \
        'hook in your .overcommit.yml file'
      end

      result = execute(['git', 'lfs', 'pre-push', remote_name, remote_url])
      return :fail, result.stderr unless result.success?

      :pass
    end
  end
end
