# frozen_string_literal: true

module Overcommit::Hook::PrePush
  # Runs Dart test suite (`pub run test`) before push
  #
  # @see https://pub.dev/packages/test#running-tests
  class PubTest < Base
    def run
      result = execute(command)
      return :pass if result.success?

      output = result.stdout + result.stderr
      [:fail, output]
    end
  end
end
