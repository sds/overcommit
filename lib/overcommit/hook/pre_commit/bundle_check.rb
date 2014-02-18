module Overcommit::Hook::PreCommit
  # Check if local Gemfile.lock matches Gemfile when either changes, unless
  # Gemfile.lock is ignored by git.
  class BundleCheck < Base
    def run
      unless in_path?('bundle')
        return :warn, 'bundler not installed -- run `gem install bundler`'
      end

      # Ignore if Gemfile.lock is not tracked by git
      return :good if command("git check-ignore #{LOCK_FILE}").success?

      result = command('bundle check')
      unless result.success?
        return :bad, result.stdout
      end

      result = command("git diff --quiet -- #{LOCK_FILE}")
      unless result.success?
        return :bad, "#{LOCK_FILE} is not up-to-date -- run `bundle check`"
      end

      :good
    end

  private

    LOCK_FILE = 'Gemfile.lock'
  end
end
