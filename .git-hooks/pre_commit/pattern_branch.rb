# frozen_string_literal: true

module Overcommit::Hook::PreCommit
  # Prevents commits to branches doesn't matching one of the configured patterns.
  class PatternBranch < Base
    def run
      error_message = validate_pattern

      return :fail, error_message if error_message
      return :pass
    end

    private

    def validate_pattern
      pattern = config['pattern']
      return :fail, 'Must have pattern to match' if pattern.empty?

      expected_pattern_branch = config['expected_pattern_branch']
      sample_branch = config['sample_branch']

      unless forbidden_branch_name?
        [
          'Branch name pattern mismatch.',
          "Expected : #{expected_pattern_branch}",
          "Sample : #{sample_branch}"
        ].join("\n")
      end
    end

    def forbidden_branch_name?
      branch_patterns.any? { |pattern| current_branch.match?(/#{pattern}/) }
    end

    def branch_patterns
      @branch_patterns ||= Array(config['pattern'])
    end

    def current_branch
      @current_branch ||= Overcommit::GitRepo.current_branch
    end
  end
end
