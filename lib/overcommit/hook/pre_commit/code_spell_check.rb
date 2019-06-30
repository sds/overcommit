# frozen_string_literal: true

module Overcommit::Hook::PreCommit
  # Runs `alfonsox` spell-checking tool against any modified code file.
  #
  # @see https://github.com/diegojromerolopez/alfonsox
  class CodeSpellCheck < Base
    def run
      # Create default file config if it does not exist

      # Run spell-check
      result = execute(command, args: applicable_files)
      return :pass if result.success?

      spellchecking_errors = result.stderr.split("\n")
      spellchecking_errors.pop

      error_messages(spellchecking_errors)
    end

    private

    # Create the error messages
    def error_messages(spellchecking_errors)
      messages = []
      spellchecking_errors.each do |spellchecking_error_i|
        error_location, word = spellchecking_error_i.split(' ')
        error_file_path, line = error_location.split(':')
        messages << Overcommit::Hook::Message.new(
          :error, error_file_path, line, "#{error_location}: #{word}"
        )
      end
      messages
    end
  end
end
