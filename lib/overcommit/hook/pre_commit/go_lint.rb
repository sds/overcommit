module Overcommit::Hook::PreCommit
  # Runs `golint` against any modified Golang files.
  class GoLint < Base
    def run
      result = execute([executable] + applicable_files)
      # Unfortunately the exit code is always 0
      return :pass if result.stdout.empty?

      [:fail, result.stdout]
    end
  end
end
