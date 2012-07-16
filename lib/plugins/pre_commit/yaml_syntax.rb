module Causes::GitHook
  class YamlSyntax < HookSpecificCheck
    include HookRegistry
    file_type :yml

    def run_check
      clean = true
      output = []
      modified_files('yml').each do |file|
        staged = StagedFile.new(file)
        begin
          YAML.load_file(staged.path)
        rescue ArgumentError => e
          output << "#{e.message} parsing #{file}"
          clean = false
        end
      end
      return (clean ? :good : :bad), output
    end
  end
end
