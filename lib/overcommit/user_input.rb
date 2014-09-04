module Overcommit
  # Encapsulates prompting for and fetching input from a user.
  class UserInput
    # @param io [IO] device to fetch input from
    def initialize(io)
      @io = io

      reopen_tty
    end

    # Get a string of input from the user (up to the next newline character).
    def get
      @io.gets
    end

    private

    # Git hooks are not interactive and will close STDIN by default.
    def reopen_tty
      # If the hook isn't interactive, we need to map STDIN to keyboard manually
      STDIN.reopen('/dev/tty') if STDIN.eof?
    rescue # rubocop:disable HandleExceptions
      # Happens in tests run with no console available
    end
  end
end
