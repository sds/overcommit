require 'overcommit/hook/shared/simple_install'

module Overcommit::Hook::Shared
  # Shared code used by all NpmInstall hooks. Runs `npm install` when a change
  # is detected in the repository's dependencies.
  #
  # @see https://www.npmjs.com/
  module NpmInstall
    include SimpleInstall

    def fail_output
      @result.stderr
    end
  end
end
