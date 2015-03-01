module Overcommit::Hook::PreCommit
  # Checks the syntax of any modified JSON files.
  class JsonSyntax < Base
    def run
      messages = []

      applicable_files.each do |file|
        begin
          JSON.parse(IO.read(file))
        rescue JSON::ParserError => e
          error = "#{e.message} parsing #{file}"
          messages << Overcommit::Hook::Message.new(:error, file, nil, error)
        end
      end

      messages
    end
  end
end
