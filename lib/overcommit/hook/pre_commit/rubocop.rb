module Overcommit::Hook::PreCommit
  # Runs `rubocop` against any modified Ruby files.
  class Rubocop < Base
    MESSAGE_TYPE_CATEGORIZER = lambda do |type|
      type.include?('W') ? :warning : :error
    end

    def run
      result = execute(command + %w[--format=emacs --force-exclusion] + applicable_files)
      return :pass if result.success?

      extract_messages(
        result.stdout.split("\n"),
        /^(?<file>[^:]+):(?<line>\d+):[^ ]+ (?<type>[^ ]+)/,
        MESSAGE_TYPE_CATEGORIZER,
      )
    end
  end
end
