# frozen_string_literal: true

module Overcommit::Hook::PrePush
  # Runs `mix test` test suite before push
  #
  # @see https://hexdocs.pm/mix/Mix.Tasks.Test.html
  class MixTest < Base
    def run
      result = execute(command)
      return :pass if result.success?

      output = result.stdout + result.stderr
      [:fail, output]
    end
  end
end
