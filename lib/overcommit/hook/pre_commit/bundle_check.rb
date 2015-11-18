module Overcommit::Hook::PreCommit
  # Check if local Gemfile.lock matches Gemfile when either changes, unless
  # Gemfile.lock is ignored by git.
  #
  # @see http://bundler.io/
  class BundleCheck < Base
    LOCK_FILE = 'Gemfile.lock'

    def run
      # Ignore if Gemfile.lock is not tracked by git
      ignored_files = execute(%w[git ls-files -o -i --exclude-standard]).stdout.split("\n")
      return :pass if ignored_files.include?(LOCK_FILE)

      result = execute(command)
      unless result.success?
        return :fail, result.stdout
      end

      :pass
    end
  end
end
