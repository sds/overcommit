module Overcommit::Hook::PreCommit
  # Runs `coffeelint` against any modified CoffeeScript files.
  class CoffeeLint < Base
    def run
      result = execute(command + %w[--quiet] + applicable_files)
      return :pass if result.success?

      [:fail, result.stdout]
    end
  end
end
