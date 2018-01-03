module Overcommit
  module Hook
    module PreCommit
      # Runs `rails_best_practices` against Ruby files
      #
      # @see https://github.com/railsbp/rails_best_practices
      class RailsBestPractices < Base
        ERROR_REGEXP = /^(?<file>(?:\w:)?[^:]+):(?<line>\d+)\s-\s(?<type>.+)/

        def run
          result = execute(command, args: applicable_files)

          return :pass if result.success?
          return [:fail, result.stderr] unless result.stderr.empty?

          extract_messages(
            filter_output(result.stdout),
            ERROR_REGEXP
          )
        end

        private

        def filter_output(stdout)
          stdout.split("\n").select do |message|
            message.match ERROR_REGEXP
          end
        end
      end
    end
  end
end
