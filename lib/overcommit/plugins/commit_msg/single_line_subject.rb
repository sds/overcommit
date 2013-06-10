module Overcommit::GitHook
  class SingleLineSubject < HookSpecificCheck
    include HookRegistry

    def run_check
      unless commit_message[1].to_s.strip.empty?
        return :warn, 'Subject should be a single line'
      end

      :good
    end
  end
end
