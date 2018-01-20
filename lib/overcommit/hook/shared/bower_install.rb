require 'overcommit/hook/shared/simple_install'

module Overcommit::Hook::Shared
  # Shared code used by all BowerInstall hooks. Runs `bower install` when a
  # change is detected in the repository's dependencies.
  #
  # @see http://bower.io/
  module BowerInstall
    include SimpleInstall

    def fail_output
      @result.stderr
    end
  end
end
