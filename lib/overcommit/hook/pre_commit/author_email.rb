module Overcommit::Hook::PreCommit
  # Checks the format of an author's email address.
  class AuthorEmail < Base
    def run
      result = execute(%w[git config --get user.email])
      email = result.stdout.chomp

      unless email =~ /#{@config['pattern']}/
        return :bad, "Author has an invalid email address: '#{email}'\n" \
                     'Set your email with ' \
                     '`git config --global user.email your_email@example.com`'
      end

      :good
    end
  end
end
