module Overcommit::Hook::Shared
  # Shared code used by all ComposerInstall hooks. Runs `composer install` when
  # a change is detected in the repository's dependencies.
  #
  # @see https://getcomposer.org/
  module ComposerInstall
    def run
      result = execute(command)
      return :fail, result.stdout unless result.success?
      :pass
    end
  end
end
