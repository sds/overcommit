module Overcommit::Hook::PreCommit
  # Checks for local paths in files and issues a warning
  class LocalPathsInGemfile < Base
    def run
      result = execute(command, args: applicable_files)

      unless result.stdout.empty?
        return :warn, "Avoid pointing to local paths in Gemfiles:\n#{result.stdout}"
      end

      :pass
    end
  end
end
