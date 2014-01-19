module Overcommit::Hook::PreCommit
  # Runs `csslint` against any modified CSS files.
  class CssLint < Base
    CSS_LINT = Overcommit::Utils.script_path('csslint-rhino.js')

    def run
      return :warn, 'Rhino is not installed' unless in_path?('rhino')

      paths = applicable_files.join(' ')

      result = command("rhino #{CSS_LINT} --quiet --format=compact #{paths} | grep 'Error - '")
      output = result.stdout
      return (output !~ /Error - (?!Unknown @ rule)/ ? :good : :bad), output
    end
  end
end
