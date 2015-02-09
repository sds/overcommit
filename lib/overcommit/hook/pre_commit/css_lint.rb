module Overcommit::Hook::PreCommit
  # Runs `csslint` against any modified CSS files.
  class CssLint < Base
    def run
      result = execute(command + applicable_files)
      return :pass if result.stdout !~ /Error - (?!Unknown @ rule)/

      [:fail, result.stdout]
    end
  end
end
