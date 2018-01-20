require 'overcommit/hook/shared/simple_install'

module Overcommit::Hook::Shared
  # Shared code used by all ComposerInstall hooks. Runs `composer install` when
  # a change is detected in the repository's dependencies.
  #
  # @see https://getcomposer.org/
  module ComposerInstall
    include SimpleInstall

    def fail_output
      @result.stdout
    end
  end
end
