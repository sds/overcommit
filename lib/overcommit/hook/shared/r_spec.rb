# frozen_string_literal: true

module Overcommit::Hook::Shared
  # Runs `rspec` test suite before push
  #
  # @see http://rspec.info/
  module RSpec
    def run
      result = if @config['include']
                 execute(command, args: applicable_files)
               else
                 execute(command)
               end

      return :pass if result.success?

      output = result.stdout + result.stderr
      [:fail, output]
    end
  end
end
