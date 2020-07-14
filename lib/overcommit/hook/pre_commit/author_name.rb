# frozen_string_literal: true

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

      if name.empty?
        return :fail,
               "Author name must be non-0 in length.\n" \
               'Set your name with `git config --global user.name "Your Name"` ' \
               'or via the GIT_AUTHOR_NAME environment variable'
      end

      :pass
    end
  end
end
