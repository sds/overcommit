module Overcommit::Hook::PreCommit
  # Checks the syntax of any modified YAML files.
  class YamlSyntax < Base
    def run
      messages = []

      applicable_files.each do |file|
        begin
          YAML.load_file(file)
        rescue ArgumentError, Psych::SyntaxError => e
          messages << Overcommit::Hook::Message.new(:error, file, nil, e.message)
        end
      end

      messages
    end
  end
end
