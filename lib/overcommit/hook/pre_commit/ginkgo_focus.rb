# frozen_string_literal: true

module Overcommit::Hook::PreCommit
  # Check for "focused" tests
  class GinkgoFocus < Base
    def run
      keywords = config['keywords']
      result = execute(command, args: [keywords.join('|')] + applicable_files)

      extract_messages(
        result.stdout.split("\n"),
        /^(?<file>(?:\w:)?[^:]+):(?<line>\d+)/,
        lambda { |_type| :warning }
      )
    end

    def applicable_test_files
      applicable_files.select do |f|
        f if f =~ /_test\.go/
      end
    end
  end
end
