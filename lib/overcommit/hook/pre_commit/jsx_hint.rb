module Overcommit::Hook::PreCommit
  # Runs `jsxhint` against any modified JSX files.
  class JsxHint < Base
    def run
      unless in_path?('jsxhint')
        return :warn, 'jsxhint not installed -- run `npm install -g jsxhint`'
      end

      result = execute(%w[jsxhint] + applicable_files)
      output = result.stdout

      return :pass if output.empty?

      [:fail, output]
    end
  end
end
