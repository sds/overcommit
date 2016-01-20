# frozen_string_literal: true

module Overcommit::Hook::PreCommit
  # Check if local Berksfile.lock matches Berksfile when either changes, unless
  # Berksfile.lock is ignored by git.
  #
  # @see http://berkshelf.com/
  class BerksfileCheck < Base
    LOCK_FILE = 'Berksfile.lock'.freeze

    def run
      # Ignore if Berksfile.lock is not tracked by git
      ignored_files = execute(%w[git ls-files -o -i --exclude-standard]).stdout.split("\n")
      return :pass if ignored_files.include?(LOCK_FILE)

      result = execute(command)
      unless result.success?
        return :fail, result.stderr
      end

      :pass
    end
  end
end
