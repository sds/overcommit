module Overcommit::Hook::PreCommit
  # Runs `golint` against any modified Golang files.
  class GoLint < Base
    def run
      unless in_path?('golint')
        return :warn, 'Run `go get `github.com/golang/lint/golint`'
      end

      result = execute(%w[golint] + applicable_files)
      # Unfortunately the exit code is always 0
      return :good if result.stdout.empty?

      [:fail, result.stdout]
    end
  end
end
