require 'overcommit/hook/shared/bower_install'

module Overcommit::Hook::PostCheckout
  # Runs `bower install` when a change is detected in the repository's
  # dependencies.
  #
  # @see {Overcommit::Hook::Shared::BowerInstall}
  class BowerInstall < Base
    include Overcommit::Hook::Shared::BowerInstall
  end
end
