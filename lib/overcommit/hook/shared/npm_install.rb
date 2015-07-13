module Overcommit::Hook::Shared
  # Shared code used by all NpmInstall hooks. Runs `npm install` when a change
  # is detected in the repository's dependencies.
  #
  # @see https://www.npmjs.com/
  module NpmInstall
    def run
      result = execute(command)
      return :fail, result.stderr unless result.success?
      :pass
    end
  end
end
