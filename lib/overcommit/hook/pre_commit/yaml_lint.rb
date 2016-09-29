module Overcommit::Hook::PreCommit
  # Runs `YAMLLint` against any modified YAML files.
  #
  # @see https://github.com/adrienverge/yamllint
  class YamlLint < Base
    def run
      result = execute(command, args: applicable_files)

      if result.success?
        :pass
      else
        return [:warn, result.stdout]
      end
    end
  end
end
