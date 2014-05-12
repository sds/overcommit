module Overcommit::Hook::PreCommit
  # Look for the multiple ways that you can focus specs with RSpec and make sure
  # that none exist.
  class RspecFocus < Base
    def run
      result = execute(%w{
                         grep
                         -nIHE
                         '^\s*((f?specify)|(f?example)|(f?describe)|(f?context)|(f?feature)|(f?scenario)|(f?it))'
                       } +
                       applicable_files +
                       %w{
                         |
                         grep
                         -E
                         '(:focused\s*=>)|(:focus\s*=>)|(focus:)|(focused:)|(:\d+:\s*fit\s)'
                       })

      unless result.stdout.empty?
        return :bad, "Focused RSpec spec found:\n#{result.stdout}"
      end

      :good
    end
  end
end
