module Overcommit::Hook::PreCommit
  # Checks for vulnerable versions of gems in Gemfile.lock.
  #
  # @see https://github.com/rubysec/bundler-audit
  class BundleAudit < Base
    LOCK_FILE = 'Gemfile.lock'.freeze

    def run
      # Ignore if Gemfile.lock is not tracked by git
      ignored_files = execute(%W[git ls-files -o -i --exclude-standard -- #{LOCK_FILE}]).
                      stdout.split("\n")
      return :pass if ignored_files.include?(LOCK_FILE)

      result = execute(command)
      if result.success?
        :pass
      else
        return [:warn, result.stdout]
      end
    end
  end
end
