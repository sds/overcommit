module Overcommit::GitHook
  class ChangeID < HookSpecificCheck
    include HookRegistry

    stealth! # Not really a 'check', but we need it to run
    required! # Not skipped when ENV['SKIP_CHECKS'] == 'all'

    SCRIPT_LOCATION = Overcommit::Utils.script_path 'gerrit-change-id'

    def run_check
      system `#{SCRIPT_LOCATION} #{@arguments.join(' ')}`
      :good
    end
  end
end
