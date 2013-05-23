module Overcommit::GitHook
  class AuthorName < HookSpecificCheck
    include HookRegistry

    def run_check
      name = `git config --get user.name`.chomp
      unless name.split(' ').count >= 2
        return :bad, "Author must have at least first and last name; " <<
                     "was: '#{name}'.\n Set your name with " <<
                     "`git config --global user.name 'Your Name'`"
      end

      :good
    end
  end
end
