require 'yaml'

module Overcommit::Hook::PreCommit
  # Checks the syntax of any modified YAML files.
  class YamlSyntax < Base
    def run
      clean = true
      output = []

      applicable_files.each do |file|
        begin
          YAML.load_file(file)
        rescue ArgumentError => e
          output << "#{e.message} parsing #{file}"
          clean = false
        end
      end

      return (clean ? :good : :bad), output
    end
  end
end
