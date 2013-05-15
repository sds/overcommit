module Overcommit::GitHook
  class RussianNovel < HookSpecificCheck
    include HookRegistry

    stealth!

    RUSSIAN_NOVEL_LENGTH = 30
    def run_check
      if user_commit_message.length > RUSSIAN_NOVEL_LENGTH
        return :warn, 'You seem to have authored a Russian novel; congratulations!'
      end

      :good
    end
  end
end
