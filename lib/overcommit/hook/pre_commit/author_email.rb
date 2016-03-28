module Overcommit::Hook::PreCommit
  # Checks the format of an author's email address.
  class AuthorEmail < Base
    def run
      email =
        if ENV.key?('GIT_AUTHOR_EMAIL')
          ENV['GIT_AUTHOR_EMAIL']
        else
          result = execute(%w[git config --get user.email])
          result.stdout.chomp
        end

      unless email =~ /#{config['pattern']}/
        return :fail,
               "Author has an invalid email address: '#{email}'\n" \
               'Set your email with ' \
               '`git config --global user.email your_email@example.com` ' \
               'or via the GIT_AUTHOR_EMAIL environment variable'
      end

      :pass
    end
  end
end
