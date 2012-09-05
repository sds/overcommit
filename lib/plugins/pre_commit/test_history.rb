module Causes::GitHook
  class TestHistory < HookSpecificCheck
    include HookRegistry

    def relevant_tests
      @relevant_test ||=
        `relevant-tests 2> /dev/null -- #{modified_files.join(' ')}`.
        split("\n").map { |r| File.expand_path r }
    end

    def skip?
      !FileTest.exist?('spec/support/record_results_formatter.rb')
    end

    TEST_RESULTS_FILE = '.spec-results'
    def run_check
      output = []
      unless relevant_tests.any?
        return :warn, 'No relevant tests for this change...write some?'
      end

      begin
        good_tests = File.open(TEST_RESULTS_FILE, 'r').readlines.map do |spec_file|
          File.expand_path spec_file.strip
        end
      rescue Errno::ENOENT
        good_tests = []
      end

      unless good_tests.any?
        return :bad,
          'The relevant tests for this change have not yet been run using `specr`'
      end

      missed_tests = (relevant_tests - good_tests)
      unless missed_tests.empty?
        output << 'The following relevant tests have not been run recently:'
        output << missed_tests.sort
        return :bad, output
      end

      # Find files modified after the tests were run
      test_time = File.mtime(TEST_RESULTS_FILE)
      untested_files = modified_files.reject do |file|
        File.mtime(file) < test_time
      end

      unless untested_files.empty?
        output << 'The following files were modified after `specr` was run.'
        output << '(their associated tests may be broken):'
        output << untested_files.sort
        return :bad, output
      end

      return :good
    end
  end
end
