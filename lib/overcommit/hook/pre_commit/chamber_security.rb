module Overcommit::Hook::PreCommit
  # Runs `chamber secure` against any modified Chamber settings files
  class ChamberSecurity < Base
    def run
      result = execute(%W[#{executable} secure --files] + applicable_files)

      return :pass if result.stdout.empty?
      [:fail, "These settings appear to need to be secured but were not: #{result.stdout}"]
    end
  end
end
