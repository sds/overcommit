require 'overcommit/hook/shared/simple_install'

module Overcommit::Hook::Shared
  # Shared code used by all YarnInstall hooks. Runs `yarn install` when a change
  # is detected in the repository's dependencies.
  #
  # @see https://yarnpkg.com/
  module YarnInstall
    include SimpleInstall

    def fail_output
      @result.stderr
    end
  end
end
