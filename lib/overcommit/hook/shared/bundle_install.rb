module Overcommit::Hook::Shared
  # Shared code used by all BundleInstall hooks. Runs `bundle install` when a
  # change is detected in the repository's dependencies.
  #
  # @see http://bundler.io/
  module BundleInstall
    def run
      result = execute(command)
      return :fail, result.stdout unless result.success?
      :pass
    end
  end
end
