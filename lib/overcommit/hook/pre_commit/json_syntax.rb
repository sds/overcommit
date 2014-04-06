require 'json'

module Overcommit::Hook::PreCommit
  # Checks the syntax of any modified JSON files.
  class JsonSyntax < Base
    def run
      output = []

      applicable_files.each do |file|
        begin
          File.open(file) { |io| JSON.load(io) }
        rescue JSON::ParserError => e
          output << "#{e.message} parsing #{file}"
        end
      end

      return :good if output.empty?

      [:bad, output]
    end
  end
end
