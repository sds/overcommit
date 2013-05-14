module Causes::GitHook
  class RussianNovel < HookSpecificCheck
    include HookRegistry

    RUSSIAN_NOVEL_LENGTH = 30
    def run_check
      count = 0
      commit_message.find do |line|
        count += 1 unless comment?(line)
        diff_started?(line)
      end

      if count > RUSSIAN_NOVEL_LENGTH
        return :warn, 'You seem to have authored a Russian novel; congratulations!'
      end

      :good
    end

  private

    def diff_started?(line)
      line =~ /^diff --git /
    end

    def comment?(line)
      line =~ /^#/
    end
  end
end
