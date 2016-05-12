module Overcommit::Hook::PreCommit
  # Check if any gems in Gemfile.lock have newer versions, unless the
  # Gemfile.lock is ignored by Git.
  #
  # @see http://bundler.io/bundle_outdated.html
  class BundleOutdated < Base
    LOCK_FILE = 'Gemfile.lock'.freeze

    def run
      # Ignore if Gemfile.lock is not tracked by git
      ignored_files = execute(%w[git ls-files -o -i --exclude-standard]).stdout.split("\n")
      return :pass if ignored_files.include?(LOCK_FILE)

      result = execute(command)
      warn_msgs = result.stdout.split("\n").
                         reject { |str| str.strip.empty? }.
                         reject { |str| (str.strip =~ /^(\[|\()?warning|deprecation/i) }
      warnings = warn_msgs.map { |msg| Overcommit::Hook::Message.new(:warning, nil, nil, msg) }

      warnings.empty? ? :pass : warnings
    end
  end
end
