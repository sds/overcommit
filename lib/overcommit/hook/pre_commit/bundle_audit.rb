# frozen_string_literal: true

module Overcommit::Hook::PreCommit
  # Checks for vulnerable versions of gems in Gemfile.lock.
  #
  # Set `update: true` to refresh ruby-advisory-db before checking. Defaults to false.
  #
  # @see https://github.com/rubysec/bundler-audit
  class BundleAudit < Base
    LOCK_FILE = 'Gemfile.lock'

    def run
      # Ignore if Gemfile.lock is not tracked by git
      ignored_files = execute(%W[git ls-files -o -i --exclude-standard -- #{LOCK_FILE}]).
                      stdout.split("\n")
      return :pass if ignored_files.include?(LOCK_FILE)

      audit_command = command
      audit_command << '--update' if config['update']

      result = execute(audit_command)
      if result.success?
        :pass
      else
        [:warn, result.stdout]
      end
    end
  end
end
