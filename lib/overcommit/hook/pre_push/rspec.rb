module Overcommit::Hook::PrePush
  # Runs `rspec` test suite before push
  class Rspec < Base
    def run
      result = execute(command)
      return :pass if result.success?

      output = result.stdout + result.stderr
      [Overcommit::Hook::Message.new(:error, nil, nil, output)]
    end
  end
end
