module Overcommit::Hook::CommitMsg
  # Checks that the commit message is not empty
  class EmptyMessage < Base
    def run
      return :pass unless empty_message?

      [:fail, 'Commit message should not be empty']
    end
  end
end
