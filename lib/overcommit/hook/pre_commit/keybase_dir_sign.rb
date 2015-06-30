module Overcommit::Hook::PreCommit
  # Runs `keybase dir sign` and `git add SIGNED.md` to sign the dir contents
  # with an OpenPGP cryptographic signature. Signs *all* files, not just
  # those that are part of the current commit.
  #
  # @see https://keybase.io/
  class KeybaseDirSign < Base
    def run
      keybase_result = execute(command)
      keybase_output = keybase_result.stdout.chomp

      if keybase_result.success? && keybase_output.empty?
        git_result = execute(['git', 'add', 'SIGNED.md'])
        git_output = git_result.stdout.chomp

        if git_result.success? && git_output.empty?
          return :pass
        end
        [:fail, git_result.stderr]
      end

      [:fail, keybase_result.stderr]
    end
  end
end
