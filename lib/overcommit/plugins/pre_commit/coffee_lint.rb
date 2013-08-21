module Overcommit::GitHook
  class CoffeeLint < HookSpecificCheck
    include HookRegistry
    file_type :coffee

    def run_check
      unless in_path? 'coffeelint'
        return :warn, 'Run `npm install -g coffeelint`'
      end

      paths  = staged.collect(&:path).join(' ')
      output = `coffeelint --quiet #{paths}`.split("\n")
      return ($?.success? ? :good : :bad), output
    end
  end
end
