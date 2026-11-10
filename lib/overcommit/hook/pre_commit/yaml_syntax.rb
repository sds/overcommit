# frozen_string_literal: true

module Overcommit::Hook::PreCommit
  # Checks the syntax of any modified YAML files.
  class YamlSyntax < Base
    def run
      messages = []

      applicable_files.each do |file|
        YAML.load_file(file, aliases: true)
      rescue ArgumentError
        begin
          YAML.load_file(file)
        rescue ArgumentError, Psych::SyntaxError => e
          messages << Overcommit::Hook::Message.new(:error, file, nil, e.message)
        end
      rescue Psych::DisallowedClass => e
        messages << error_message(file, e)
      end

      messages
    end

    private

    def error_message(file, error)
      text = "#{file}: #{error.message}"
      Overcommit::Hook::Message.new(:error, file, nil, text)
    end
  end
end
