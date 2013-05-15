module Overcommit::GitHook
  class CausesEmail < HookSpecificCheck
    include HookRegistry

    def run_check
      email = `git config --get user.email`.chomp
      unless email =~ /@causes\.com$/
        return :bad, "Author must use a causes.com address; was '#{email}'.\n" <<
                     "Set user with `git config --global user.email YOUR_EMAIL@causes.com`"
      end

      :good
    end
  end
end
