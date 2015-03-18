module Overcommit::Hook::PreCommit
  # Checks the syntax of any modified XML files.
  class XmlSyntax < Base
    def run
      messages = []

      applicable_files.each do |file|
        begin
          REXML::Document.new(IO.read(file))
        rescue REXML::ParseException => e
          error = "Error parsing #{file}: #{e.message}"
          messages << Overcommit::Hook::Message.new(:error, file, nil, error)
        end
      end

      messages
    end
  end
end
