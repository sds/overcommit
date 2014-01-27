module Overcommit::Hook::PreCommit
  # Runs `csslint` against any modified CSS files.
  class CssLint < Base
    def run
      unless in_path?('csslint')
        return :warn, 'csslint not installed -- run `npm install -g csslint`'
      end

      paths = applicable_files.join(' ')

      result = command("csslint --quiet --format=compact #{paths} | grep 'Error - '")
      output = result.stdout
      return (output !~ /Error - (?!Unknown @ rule)/ ? :good : :bad), output
    end
  end
end
