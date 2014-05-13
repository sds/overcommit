module Overcommit::Hook::PreCommit
  # Runs `chamber secure` against any modified conventional Chamber settings
  # files
  class ChamberSecurity < Base
    def run
      unless in_path?('chamber')
        return :warn, 'Run `gem install chamber`'
      end

      result = execute(%w[chamber secure --echo --files] + applicable_files)

      if result.stdout.empty?
        :good
      else
        [:bad, "These settings appear to need to be secured but were not: #{result.stdout}"]
      end
    end
  end
end
