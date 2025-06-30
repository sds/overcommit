# frozen_string_literal: true

require 'overcommit'
require 'overcommit/hook/pre_commit/base'

module Overcommit
  module Hook
    module PreCommit
      # Runs `solargraph typecheck` against any modified Ruby files.
      #
      # @see https://github.com/castwide/solargraph
      class Solargraph < Base
        MESSAGE_REGEX = /^\s*(?<file>(?:\w:)?[^:]+):(?<line>\d+) - /.freeze

        def run
          result = execute(command, args: applicable_files)
          return :pass if result.success?

          stderr_lines = remove_harmless_glitches(result.stderr)
          violation_lines = result.stdout.split("\n").grep(MESSAGE_REGEX)
          if violation_lines.empty?
            if stderr_lines.empty?
              [:fail, 'Solargraph failed to run']
            else
              # let's feed it stderr so users see the errors
              extract_messages(stderr_lines, MESSAGE_REGEX)
            end
          else
            extract_messages(violation_lines, MESSAGE_REGEX)
          end
        end

        private

        # @param stderr [String]
        #
        # @return [Array<String>]
        def remove_harmless_glitches(stderr)
          stderr.split("\n").reject do |line|
            line.include?('[WARN]') ||
              line.include?('warning: parser/current is loading') ||
              line.include?('Please see https://github.com/whitequark')
          end
        end
      end
    end
  end
end
