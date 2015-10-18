module Overcommit
  # Get configuration options from git
  module GitConfig
    module_function

    def comment_character
      char = `git config --get core.commentchar`.chomp
      char = '#' if char == ''
      char
    end
  end
end
