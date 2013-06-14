module Overcommit::GitHook
  class CssLinter < HookSpecificCheck
    include HookRegistry
    file_type :css

    CSS_LINTER_PATH = Overcommit::Utils.script_path 'csslint-rhino.js'

    def run_check
      return :warn, "Rhino is not installed" unless in_path? 'rhino'

      paths = staged.map { |s| s.path }.join(' ')

      output = `rhino #{CSS_LINTER_PATH} --quiet --format=compact #{paths} | grep 'Error - '`
      staged.each { |s| output = s.filter_string(output) }
      return (output !~ /Error - (?!Unknown @ rule)/ ? :good : :bad), output
    end
  end
end
