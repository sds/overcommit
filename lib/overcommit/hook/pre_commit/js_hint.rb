module Overcommit::Hook::PreCommit
  # Runs `jshint` against any modified JavaScript files.
  class JsHint < Base
    def run
      unless in_path?('jshint')
        return :warn, 'jshint not installed -- run `npm install -g jshint`'
      end

      result = command(%w[jshint] + applicable_files)
      output = result.stdout

      return (output.empty? ? :good : :bad), output
    end
  end
end
