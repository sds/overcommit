module Overcommit::Hook::CommitMsg
  # Checks for long commit messages (not good or bad--just fun to point out)
  class RussianNovel < Base
    def run
      if commit_message_lines.length >= @config['max_length']
        return :warn, 'You seem to have authored a Russian novel; congratulations!'
      end

      :good
    end
  end
end
