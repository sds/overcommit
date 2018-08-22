module Overcommit::Hook::PreCommit
  # Runs `ruumba` (`rubocop`) against any modified ERB files.
  #
  # @see https://github.com/ericqweinstein/ruumba
  class Ruumba < RuboCop
  end
end
