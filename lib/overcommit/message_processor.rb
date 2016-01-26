# frozen_string_literal: true

module Overcommit
  # Utility class that encapsulates the handling of hook messages and whether
  # they affect lines the user has modified or not.
  #
  # This class exposes an endpoint that extracts an appropriate hook/status
  # output tuple from an array of {Overcommit::Hook::Message}s, respecting the
  # configuration settings for the given hook.
  class MessageProcessor
    ERRORS_MODIFIED_HEADER = 'Errors on modified lines:'.freeze
    WARNINGS_MODIFIED_HEADER = 'Warnings on modified lines:'.freeze
    ERRORS_UNMODIFIED_HEADER = "Errors on lines you didn't modify:".freeze
    WARNINGS_UNMODIFIED_HEADER = "Warnings on lines you didn't modify:".freeze
    ERRORS_GENERIC_HEADER = 'Errors:'.freeze
    WARNINGS_GENERIC_HEADER = 'Warnings:'.freeze

    # @param hook [Overcommit::Hook::Base]
    # @param unmodified_lines_setting [String] how to treat messages on
    #   unmodified lines
    def initialize(hook, unmodified_lines_setting)
      @hook = hook
      @setting = unmodified_lines_setting
    end

    # Returns a hook status/output tuple from the messages this processor was
    # initialized with.
    #
    # @return [Array<Symbol,String>]
    def hook_result(messages)
      status, output = basic_status_and_output(messages)

      # Nothing to do if there are no problems to begin with
      return [status, output] if status == :pass

      # Return as-is if this type of hook doesn't have the concept of modified lines
      return [status, output] unless @hook.respond_to?(:modified_lines_in_file)

      handle_modified_lines(messages, status)
    end

    private

    def handle_modified_lines(messages, status)
      messages = remove_ignored_messages(messages)

      messages_with_line, generic_messages = messages.partition(&:line)

      # Always print generic messages first
      output = print_messages(
        generic_messages,
        ERRORS_GENERIC_HEADER,
        WARNINGS_GENERIC_HEADER
      )

      messages_on_modified_lines, messages_on_unmodified_lines =
        messages_with_line.partition { |message| message_on_modified_line?(message) }

      output += print_messages(
        messages_on_modified_lines,
        ERRORS_MODIFIED_HEADER,
        WARNINGS_MODIFIED_HEADER
      )
      output += print_messages(
        messages_on_unmodified_lines,
        ERRORS_UNMODIFIED_HEADER,
        WARNINGS_UNMODIFIED_HEADER
      )

      [transform_status(status, generic_messages + messages_on_modified_lines), output]
    end

    def transform_status(status, messages_on_modified_lines)
      # `report` indicates user wants the original status
      return status if @setting == 'report'

      error_messages, warning_messages =
        messages_on_modified_lines.partition { |msg| msg.type == :error }

      if can_upgrade_to_warning?(status, error_messages)
        status = :warn
      end

      if can_upgrade_to_passing?(status, warning_messages)
        status = :pass
      end

      status
    end

    def can_upgrade_to_warning?(status, error_messages)
      status == :fail && error_messages.empty?
    end

    def can_upgrade_to_passing?(status, warning_messages)
      status == :warn && @setting == 'ignore' && warning_messages.empty?
    end

    # Returns status and output for messages assuming no special treatment of
    # messages occurring on unmodified lines.
    def basic_status_and_output(messages)
      status =
        if messages.any? { |message| message.type == :error }
          :fail
        elsif messages.any? { |message| message.type == :warning }
          :warn
        else
          :pass
        end

      output = ''
      if messages.any?
        output += messages.join("\n") + "\n"
      end

      [status, output]
    end

    def print_messages(messages, error_heading, warning_heading)
      output = ''
      errors, warnings = messages.partition { |msg| msg.type == :error }

      if errors.any?
        output += "#{error_heading}\n#{errors.join("\n")}\n"
      end

      if warnings.any?
        output += "#{warning_heading}\n#{warnings.join("\n")}\n"
      end

      output
    end

    def remove_ignored_messages(messages)
      # If user wants to ignore messages on unmodified lines, simply remove them
      return messages unless @setting == 'ignore'

      messages.select { |message| message_on_modified_line?(message) }
    end

    def message_on_modified_line?(message)
      # Message without line number assumed to apply to entire file
      return true unless message.line

      @hook.modified_lines_in_file(message.file).include?(message.line)
    end
  end
end
