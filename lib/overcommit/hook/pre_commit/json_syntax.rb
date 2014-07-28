require 'json'

module Overcommit::Hook::PreCommit
  # Checks the syntax of any modified JSON files.
  class JsonSyntax < Base
    def run
      output = []

      applicable_files.each do |file|
        begin
          JSON.parse(IO.read(file))
        rescue JSON::ParserError => e
          output << "#{e.message} parsing #{file}"
        end
      end

      return :good if output.empty?

      [:fail, output]
    end
  end
end
