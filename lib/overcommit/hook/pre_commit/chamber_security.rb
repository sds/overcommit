module Overcommit::Hook::PreCommit
  # Runs `chamber secure` against any modified Chamber settings files.
  #
  # @see https://github.com/thekompanee/chamber
  class ChamberSecurity < Base
    def run
      result = execute(command, args: applicable_files)

      return :pass if result.stdout.empty?
      [:fail, "These settings appear to need to be secured but were not: #{result.stdout}"]
    end
  end
end
