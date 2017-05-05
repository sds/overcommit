module Overcommit::Hook::PreCommit
  # Runs LicenseFinder if any of your package manager declaration files have changed
  # See more about LicenseFinder at https://github.com/pivotal/LicenseFinde
  class LicenseFinder < Base
    def run
      result = execute(command)
      return :pass if result.success?
      output = result.stdout + result.stderr
      [:fail, output]
    end
  end
end
