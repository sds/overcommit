require 'overcommit/hook/shared/composer_install'

module Overcommit::Hook::PostCheckout
  # Runs `composer install` when a change is detected in the repository's
  # dependencies.
  #
  # @see {Overcommit::Hook::Shared::ComposerInstall}
  class ComposerInstall < Base
    include Overcommit::Hook::Shared::ComposerInstall
  end
end
