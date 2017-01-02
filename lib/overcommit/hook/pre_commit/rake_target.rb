require 'overcommit/hook/shared/rake_target'

module Overcommit::Hook::PreCommit
  # Runs rake targets
  #
  # @see {Overcommit::Hook::Shared::RakeTarget}
  class RakeTarget < Base
    include Overcommit::Hook::Shared::RakeTarget
  end
end
