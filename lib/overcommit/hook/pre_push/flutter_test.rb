# frozen_string_literal: true

module Overcommit::Hook::PrePush
  # Runs Flutter test suite (`flutter test`) before push
  #
  # @see https://api.flutter.dev/flutter/flutter_test/flutter_test-library.html
  class FlutterTest < Base
    def run
      result = execute(command)
      return :pass if result.success?

      output = result.stdout + result.stderr
      [:fail, output]
    end
  end
end
