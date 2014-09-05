module Overcommit::Hook::PreCommit
  # Runs `travis-lint` against any modified Travis CI files.
  class TravisLint < Base
    def run
      result = execute([executable] + applicable_files)
      return :pass if result.success?

      [:fail, result.stdout.strip]
    end
  end
end
