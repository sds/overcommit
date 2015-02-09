module Overcommit::Hook::PreCommit
  # Runs `jsxhint` against any modified JSX files.
  class JsxHint < Base
    def run
      result = execute(command + applicable_files)
      output = result.stdout

      return :pass if output.empty?

      [:fail, output]
    end
  end
end
