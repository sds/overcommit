module Overcommit::Hook::PreCommit
  # Check if local Berksfile.lock matches Berksfile when either changes, unless
  # Berksfile.lock is ignored by git.
  class BerksfileCheck < Base
    LOCK_FILE = 'Berksfile.lock'

    def run
      unless in_path?('berks')
        return :warn, 'Berkshelf not installed -- run `gem install berkshelf`'
      end

      # Ignore if Berksfile.lock is not tracked by git
      return :good if execute(%w[git check-ignore] + [LOCK_FILE]).success?

      result = execute(%w[berks list --quiet])
      unless result.success?
        return :bad, result.stderr
      end

      :good
    end
  end
end
