module Overcommit::Hook::CommitMsg
  # Checks for long commit messages (not good or bad--just fun to point out)
  class RussianNovel < Base
    RUSSIAN_NOVEL_LENGTH = 30

    def run
      if commit_message_lines.length >= RUSSIAN_NOVEL_LENGTH
        return :warn, 'You seem to have authored a Russian novel; congratulations!'
      end

      :pass
    end
  end
end
