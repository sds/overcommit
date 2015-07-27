module Overcommit::Hook::PreCommit
  # Runs `travis-lint` against any modified Travis CI files.
  #
  # @see https://github.com/travis-ci/travis.rb
  class TravisLint < Base
    def run
      result = execute(command, args: applicable_files)
      return :pass if result.success?

      [:fail, (result.stdout + result.stderr).strip]
    end
  end
end
