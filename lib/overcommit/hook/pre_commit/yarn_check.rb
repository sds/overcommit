# frozen_string_literal: true

module Overcommit::Hook::PreCommit
  # Check if local yarn.lock matches package.json when either changes, unless
  # yarn.lock is ignored by git.
  #
  # @see https://yarnpkg.com/en/docs/cli/check
  class YarnCheck < Base
    LOCK_FILE = 'yarn.lock'.freeze

    # A lot of the errors returned by `yarn check` are outside the developer's control
    # (are caused by bad package specification, in the hands of the upstream maintainer)
    # So limit reporting to errors the developer can do something about
    ACTIONABLE_ERRORS = [
      'Lockfile does not contain pattern'.freeze,
    ].freeze

    def run
      # Ignore if yarn.lock is not tracked by git
      ignored_files = execute(%w[git ls-files -o -i --exclude-standard]).stdout.split("\n")
      return :pass if ignored_files.include?(LOCK_FILE)

      previous_lockfile = File.exist?(LOCK_FILE) ? File.read(LOCK_FILE) : nil
      result = execute(command)
      new_lockfile = File.exist?(LOCK_FILE) ? File.read(LOCK_FILE) : nil

      # `yarn check` also throws many warnings, which should be ignored here
      errors_regex = Regexp.new("^error (.*)(#{ACTIONABLE_ERRORS.join('|')})(.*)$")
      errors = errors_regex.match(result.stderr)
      unless errors.nil? && previous_lockfile == new_lockfile
        return :fail, "#{LOCK_FILE} is not up-to-date -- run `yarn install`"
      end

      :pass
    end
  end
end
