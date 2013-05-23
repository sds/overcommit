module Overcommit::GitHook
  class TextWidth < HookSpecificCheck
    include HookRegistry

    def run_check
      if user_commit_message.first.size > 60
        return :warn, 'Please keep the subject < ~60 characters'
      end

      user_commit_message.each do |line|
        chomped = line.chomp
        if chomped.size > 72
          return :warn, "> 72 characters, please hard wrap: '#{chomped}'"
        end
      end

      :good
    end
  end
end
