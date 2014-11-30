module Overcommit::Hook::PreCommit
  # Runs `scss-lint` against any modified SCSS files.
  class ScssLint < Base
    MESSAGE_TYPE_CATEGORIZER = lambda do |type|
      type.include?('W') ? :warning : :error
    end

    def run
      result = execute([executable] + applicable_files)
      return :pass if result.success?

      extract_messages(
        result.stdout.split("\n"),
        /^(?<file>[^:]+):(?<line>\d+)[^ ]* (?<type>[^ ]+)/,
        MESSAGE_TYPE_CATEGORIZER,
      )
    end
  end
end
