require 'tempfile'

module Overcommit::Hook::CommitMsg
  # Checks the commit message for potential misspellings with `hunspell`.
  #
  # @see http://hunspell.sourceforge.net/
  class SpellCheck < Base
    Misspelling = Struct.new(:word, :suggestions)

    MISSPELLING_REGEX = /^[&#]\s(?<word>\w+)(?:.+?:\s(?<suggestions>.*))?/

    def run
      result = execute(command + [uncommented_commit_msg_file])
      return [:fail, "Error running spellcheck: #{result.stderr.chomp}"] unless result.success?

      misspellings = parse_misspellings(result.stdout)
      return :pass if misspellings.empty?

      messages = misspellings.map do |misspelled|
        msg = "Potential misspelling: #{misspelled.word}."
        msg += " Suggestions: #{misspelled.suggestions}" unless misspelled.suggestions.nil?
        msg
      end

      [:warn, messages.join("\n")]
    end

    private

    def uncommented_commit_msg_file
      ::Tempfile.open('commit-msg') do |file|
        file.write(commit_message)
        file.path
      end
    end

    def parse_misspellings(output)
      output.scan(MISSPELLING_REGEX).map do |word, suggestions|
        Misspelling.new(word, suggestions)
      end
    end
  end
end
