module Causes::GitHook
  class ScssLint < HookSpecificCheck
    include HookRegistry
    file_type :scss

    def run_check
      begin
        require 'scss_lint'
      rescue LoadError
        return :warn, 'scss-lint not installed -- run `gem install scss-lint`'
      end

      paths = staged.map { |s| s.path }.join(' ')

      output = `scss-lint #{paths} 2>&1`

      staged.each { |s| output = s.filter_string(output) }
      return (output.empty? ? :good : :bad), output
    end
  end
end
