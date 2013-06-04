module Overcommit::GitHook
  class CoffeeLint < HookSpecificCheck
    include HookRegistry
    file_type :coffee

    def run_check
      unless in_path? 'coffeelint'
        return :warn, 'Run `npm install -g coffeelint`'
      end

      output = `coffeelint --quiet #{(staged.join(' '))}`.split("\n")
      return ($?.success? ? :good : :bad), output
    end
  end
end
