module Causes::GitHook
  class ChangeID < HookSpecificCheck
    include HookRegistry

    stealth! # Not really a 'check', but we need it to run

    SCRIPT_LOCATION = File.join(File.dirname(__FILE__),
                                '..', '..', '..',
                                'scripts/gerrit-change-id')
    def run_check
      system `#{SCRIPT_LOCATION} #{@arguments.join(' ')}`
      :good
    end
  end
end
