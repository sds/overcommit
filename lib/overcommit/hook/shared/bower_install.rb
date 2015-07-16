module Overcommit::Hook::Shared
  # Shared code used by all BowerInstall hooks. Runs `bower install` when a
  # change is detected in the repository's dependencies.
  #
  # @see http://bower.io/
  module BowerInstall
    def run
      result = execute(command)
      return :fail, result.stderr unless result.success?
      :pass
    end
  end
end
