module Overcommit::Hook::PreCommit
  # Runs `phpstan` against any modified PHP files.
  # For running `phpstan` with Laravel, it requires setup with `ide_helper`.
  #
  # References:
  # https://github.com/phpstan/phpstan/issues/239
  # https://gist.github.com/edmondscommerce/89695c9cd2584fefdf540fb1c528d2c2
  class PhpStan < Base
    MESSAGE_REGEX = /^(?<file>.+)\:(?<line>\d+)\:(?<message>.+)/

    def run
      messages = []

      result = execute(command, args: applicable_files)

      unless result.success?
        messages += result.stdout.lstrip.split("\n")
      end

      return :pass if messages.empty?

      extract_messages(
        messages,
        MESSAGE_REGEX
      )
    end
  end
end
