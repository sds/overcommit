module Overcommit::Hook::PreCommit
  # Ensures that a commit author has a name with at least first and last names.
  class AuthorName < Base
    def run
      name =
        if ENV.key?('GIT_AUTHOR_NAME')
          ENV['GIT_AUTHOR_NAME']
        else
          result = execute(%w[git config --get user.name])
          result.stdout.chomp
        end

      unless name.split(' ').count >= 2
        return :fail,
               "Author must have at least first and last name, but was: #{name}.\n" \
               'Set your name with `git config --global user.name "Your Name"` ' \
               'or via the GIT_AUTHOR_NAME environment variable'
      end

      :pass
    end
  end
end
