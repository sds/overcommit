# frozen_string_literal: true

module Overcommit::Hook::PreCommit
  #
  # Spell check of the code.
  #
  class SpellCheck < Base
    def run
      # Create default file config if it does not exist

      # Run rake spellcheck task
      args = flags + applicable_files
      result = execute(command, args: args)
      spellchecking_errors = result.split('\n')

      # Check the if there are spelling errors
      return :pass if spellchecking_errors.length.zero?

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
