require 'yaml'

module Overcommit::GitHook
  class YamlSyntax < HookSpecificCheck
    include HookRegistry
    file_type :yml

    def run_check
      clean = true
      output = []
      staged.each do |path|
        begin
          YAML.load_file(path)
        rescue ArgumentError => e
          output << "#{e.message} parsing #{path}"
          clean = false
        end
      end
      return (clean ? :good : :bad), output
    end
  end
end
