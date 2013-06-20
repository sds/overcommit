module Overcommit::GitHook
  class JSSyntax < HookSpecificCheck
    include HookRegistry
    file_type :js

    def run_check
      return :warn, 'Need either `jshint` or `rhino` in path' unless runner

      paths = staged.map { |s| s.path }.join(' ')
      output = runner.call(paths)
      staged.each { |s| output = s.filter_string(output) }

      return (output.empty? ? :good : :bad), output
    end

  private

    JS_HINT_PATH        = Overcommit::Utils.script_path 'jshint.js'
    JS_HINT_RUNNER_PATH = Overcommit::Utils.script_path 'jshint_runner.js'

    def runner
      if in_path? 'jshint'
        lambda { |paths| `jshint #{paths}` }
      elsif in_path? 'rhino'
        lambda do |paths|
          `rhino -strict -f #{JS_HINT_PATH} #{JS_HINT_RUNNER_PATH} #{paths} 2>&1 | grep -v warning | grep -v -e '^js: '`
        end
      end
    end
  end
end
