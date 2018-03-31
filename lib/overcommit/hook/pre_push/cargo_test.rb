module Overcommit::Hook::PrePush
  # Runs `cargo test` before push if Rust files changed
  class CargoTest < Base
    def run
      result = execute(command)
      return :pass if result.success?
      [:fail, result.stdout]
    end
  end
end
