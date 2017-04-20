module Overcommit::Hook::PreCommit
  # Runs `hadolint` against any modified Dockefile files.
  #
  # @see http://hadolint.lukasmartinelli.ch/
  class Hadolint < Base
    def run
      output = ''
      success = true

      # hadolint doesn't accept multiple arguments
      applicable_files.each do |dockerfile|
        result = execute(command, args: Array(dockerfile))
        output += result.stdout
        success &&= result.success?
      end

      return :pass if success

      extract_messages(
        output.split("\n"),
        /^(?<file>[^:]+):(?<line>\d+)/,
      )
    end
  end
end
