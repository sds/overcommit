module Overcommit::Hook::CommitMsg
  # Ensures the number of columns the subject and commit message lines occupy is
  # under the preferred limits.
  class TextWidth < Base
    def run
      if commit_message.first.size > 60
        return :warn, 'Please keep the subject < ~60 characters'
      end

      commit_message.each do |line|
        chomped = line.chomp
        if chomped.size > 72
          return :warn, "> 72 characters, please hard wrap: '#{chomped}'"
        end
      end

      :good
    end
  end
end
