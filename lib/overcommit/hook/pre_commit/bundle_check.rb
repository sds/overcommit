# frozen_string_literal: true

module Overcommit::Hook::PreCommit
  # Check if local Gemfile.lock matches Gemfile when either changes, unless
  # Gemfile.lock is ignored by git.
  #
  # @see http://bundler.io/
  class BundleCheck < Base
    LOCK_FILE = 'Gemfile.lock'.freeze

    def run
      # Ignore if Gemfile.lock is not tracked by git
      ignored_files = execute(%w[git ls-files -o -i --exclude-standard]).stdout.split("\n")
      return :pass if ignored_files.include?(LOCK_FILE)

      previous_lockfile = File.read(LOCK_FILE) if File.exist?(LOCK_FILE)

      result = execute(command)
      unless result.success?
        return :fail, result.stdout
      end

      new_lockfile = File.read(LOCK_FILE) if File.exist?(LOCK_FILE)
      if previous_lockfile != new_lockfile
        return :fail, "#{LOCK_FILE} is not up-to-date -- run `#{command.join(' ')}`"
      end

      :pass
    end
  end
end
