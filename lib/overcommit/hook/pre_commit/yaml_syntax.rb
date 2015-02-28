module Overcommit::Hook::PreCommit
  # Checks the syntax of any modified YAML files.
  class YamlSyntax < Base
    def run
      output = []

      applicable_files.each do |file|
        begin
          YAML.load_file(file)
        rescue ArgumentError => e
          output << "#{e.message} parsing #{file}"
        end
      end

      return :pass if output.empty?

      [:fail, output]
    end
  end
end
