require 'forwardable'

module Overcommit::Hook::PreCommit
  # Functionality common to all pre-commit hooks.
  class Base < Overcommit::Hook::Base
    extend Forwardable

    def_delegators :@context, :modified_lines_in_file

    private

    # Extract file, line number, and type of message from an error/warning
    # messages in output.
    #
    # Assumes each element of `output` is a separate error/warning with all
    # information necessary to identify it.
    #
    # @param output_messages [Array<String>] unprocessed error/warning messages
    # @param regex [Regexp] regular expression defining `file`, `line` and
    #   `type` capture groups used to extract file locations and error/warning
    #   type from each line of output
    # @param type_categorizer [Proc] function executed against the `type`
    #   capture group to convert it to a `:warning` or `:error` symbol. Assumes
    #   `:error` if `nil`.
    # @raise [RuntimeError] line of output did not match regex
    # @return [Array<Message>]
    def extract_messages(output_messages, regex, type_categorizer = nil)
      output_messages.map do |message|
        unless match = message.match(regex)
          raise 'Unexpected output: unable to determine line number or type ' \
                "of error/warning for message '#{message}'"
        end

        file = extract_file(match, message)
        line = extract_line(match, message) unless match[:line].nil?
        type = extract_type(match, message, type_categorizer)

        Overcommit::Hook::Message.new(type, file, line, message)
      end
    end

    def extract_file(match, message)
      if match[:file].nil? || match[:file].empty?
        raise "Unexpected output: no file found in '#{message}'"
      end

      match[:file]
    end

    def extract_line(match, message)
      Integer(match[:line])
    rescue ArgumentError, TypeError
      raise "Unexpected output: invalid line number found in '#{message}'"
    end

    def extract_type(match, message, type_categorizer)
      if type_categorizer
        type_match = match.names.include?('type') ? match[:type] : nil
        type = type_categorizer.call(type_match)
        unless Overcommit::Hook::MESSAGE_TYPES.include?(type)
          raise "Invalid message type '#{type}' for '#{message}': must " \
                "be one of #{Overcommit::Hook::MESSAGE_TYPES.inspect}"
        end
        type
      else
        :error # Assume error since no categorizer was defined
      end
    end
  end
end
