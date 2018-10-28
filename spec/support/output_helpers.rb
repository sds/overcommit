# frozen_string_literal: true

# Helpers for capturing output streams in tests.
module OutputHelpers
  module_function

  def capture_stdout
    original = $stdout
    $stdout = output = StringIO.new

    yield

    output.string
  ensure
    $stdout = original
  end
end
