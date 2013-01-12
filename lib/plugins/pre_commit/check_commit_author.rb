module Causes::GitHook
  class CheckCommitAuthor < HookSpecificCheck
    include HookRegistry

    def run_check
      name = `git config --get user.name`.strip
      unless name.split(' ').count >= 2
        return :bad, "Author must have at least first and last name; " <<
                     "was: '#{name}'.\n Set your name with " <<
                     "`git config --global user.name 'Your Name'`"
      end

      email = `git config --get user.email`.strip
      unless email =~ /@causes\.com$/
        return :bad, "Author must use a causes.com address; was '#{email}'.\n" <<
                     "Set user with `git config --global user.email YOUR_EMAIL@causes.com`"
      end

      :good
    end
  end
end
