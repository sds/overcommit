require 'overcommit/hook/shared/simple_install'

module Overcommit::Hook::Shared
  # Shared code used by all BundleInstall hooks. Runs `bundle install` when a
  # change is detected in the repository's dependencies.
  #
  # @see http://bundler.io/
  module BundleInstall
    include SimpleInstall

    def fail_output
      @result.stdout
    end
  end
end
