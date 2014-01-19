module Overcommit::Hook::PreCommit
  # Runs `jshint` against any modified JavaScript files.
  class JsHint < Base
    def run
      return :warn, 'Need either `jshint` or `rhino` in path' unless runner

      result = runner.call(applicable_files.join(' '))
      output = result.stdout

      return (output.empty? ? :good : :bad), output
    end

  private

    JS_HINT_PATH        = Overcommit::Utils.script_path 'jshint.js'
    JS_HINT_RUNNER_PATH = Overcommit::Utils.script_path 'jshint_runner.js'

    def runner
      if in_path?('jshint')
        lambda { |paths| command("jshint #{paths}") }
      elsif in_path?('rhino')
        lambda do |paths|
          command("rhino -strict -f #{JS_HINT_PATH} #{JS_HINT_RUNNER_PATH} #{paths} 2>&1 | grep -v warning | grep -v -e '^js: '")
        end
      end
    end
  end
end
