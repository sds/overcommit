module Overcommit::Hook::PreCommit
  # Runs `scss-lint` against any modified SCSS files.
  #
  # @see https://github.com/brigade/scss-lint
  class ScssLint < Base
    MESSAGE_TYPE_CATEGORIZER = lambda do |type|
      type.include?('W') ? :warning : :error
    end

    def run
      result = execute(command + applicable_files)

      # Status code 81 indicates the applicable files were all filtered by
      # exclusions defined by the configuration. In this case, we're happy to
      # return success since there were technically no lints.
      return :pass if [0, 81].include?(result.status)

      # Any status that isn't indicating lint warnings or errors indicates failure
      return :fail, result.stdout unless [1, 2].include?(result.status)

      extract_messages(
        result.stdout.split("\n"),
        /^(?<file>(?:\w:)?[^:]+):(?<line>\d+)[^ ]* (?<type>[^ ]+)/,
        MESSAGE_TYPE_CATEGORIZER,
      )
    end
  end
end
