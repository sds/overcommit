# frozen_string_literal: true

module Overcommit::Hook::Shared
  # Shared code used by all Pronto hooks. Runs pronto linters.

  # @see https://github.com/prontolabs/pronto
  module Pronto
    MESSAGE_TYPE_CATEGORIZER = lambda do |type|
      type.include?('E') ? :error : :warning
    end

    MESSAGE_REGEX = /^(?<file>(?:\w:)?[^:]+):(?<line>\d+) (?<type>[^ ]+)/.freeze

    def run
      result = execute(command)
      return :pass if result.success?

      # e.g. runtime errors
      generic_errors = extract_messages(
        result.stderr.split("\n"),
        /^(?<type>[a-z]+)/i
      )

      pronto_infractions = extract_messages(
        result.stdout.split("\n").select { |line| line.match?(MESSAGE_REGEX) },
        MESSAGE_REGEX,
        MESSAGE_TYPE_CATEGORIZER,
      )

      generic_errors + pronto_infractions
    end
  end
end
