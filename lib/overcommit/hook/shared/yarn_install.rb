module Overcommit::Hook::Shared
  # Shared code used by all YarnInstall hooks. Runs `yarn install` when a change
  # is detected in the repository's dependencies.
  #
  # @see https://yarnpkg.com/
  module YarnInstall
    def run
      result = execute(command)
      return :fail, result.stderr unless result.success?
      :pass
    end
  end
end
