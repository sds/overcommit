module Overcommit::Hook::PreCommit
  # Runs `scss-lint` against any modified SCSS files.
  #
  # @see https://github.com/brigade/scss-lint
  class ScssLint < Base
    def run
      result = execute(command, args: applicable_files)

      # Status code 81 indicates the applicable files were all filtered by
      # exclusions defined by the configuration. In this case, we're happy to
      # return success since there were technically no lints.
      return :pass if [0, 81].include?(result.status)

      # Any status that isn't indicating lint warnings or errors indicates failure
      return :fail, (result.stdout + result.stderr) unless [1, 2].include?(result.status)

      begin
        collect_lint_messages(JSON.parse(result.stdout))
      rescue JSON::ParserError => ex
        return :fail, "Unable to parse JSON returned by SCSS-Lint: #{ex.message}\n" \
                      "STDOUT: #{result.stdout}\nSTDERR: #{result.stderr}"
      end
    end

    private

    def collect_lint_messages(files_to_lints)
      files_to_lints.flat_map do |path, lints|
        lints.map do |lint|
          severity = lint['severity'] == 'warning' ? :warning : :error

          message = lint['reason']
          message = "#{lint['linter']}: #{message}" if lint['linter']
          message = "#{path}:#{lint['line']} #{message}"

          Overcommit::Hook::Message.new(severity, path, lint['line'], message)
        end
      end
    end
  end
end
