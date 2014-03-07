module Overcommit::Hook::PreCommit
  # Runs `travis-lint` against any modified Travis CI files.
  class TravisLint < Base
    def run
      unless in_path?('travis-lint')
        return :warn, 'Run `gem install travis-lint`'
      end

      result = execute(%w[travis-lint] + applicable_files)
      return :good if result.success?
      return :bad, result.stdout.strip
    end
  end
end
