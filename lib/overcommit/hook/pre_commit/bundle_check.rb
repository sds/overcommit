module Overcommit::Hook::PreCommit
  # Check if local Gemfile.lock matches Gemfile when either changes, unless
  # Gemfile.lock is ignored by git.
  class BundleCheck < Base
    LOCK_FILE = 'Gemfile.lock'

    def run
      unless in_path?('bundle')
        return :warn, 'bundler not installed -- run `gem install bundler`'
      end

      # Ignore if Gemfile.lock is not tracked by git
      return :good if execute(%w[git check-ignore] + [LOCK_FILE]).success?

      result = execute(%w[bundle check])
      unless result.success?
        return :bad, result.stdout
      end

      result = execute(%w[git diff --quiet --] + [LOCK_FILE])
      unless result.success?
        return :bad, "#{LOCK_FILE} is not up-to-date -- run `bundle check`"
      end

      :good
    end
  end
end
