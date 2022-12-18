# frozen_string_literal: true

module Overcommit::Hook::PreCommit
  # Runs `mix format --check-formatted` against any modified ex/heex/exs files.
  #
  # @see https://hexdocs.pm/mix/main/Mix.Tasks.Format.html
  class MixFormat < Base
    # example message:
    # ** (Mix) mix format failed due to --check-formatted.
    # The following files are not formatted:
    #
    #   * lib/file1.ex
    #   * lib/file2.ex
    FILES_REGEX = /^\s+\*\s+(?<file>.+)$/.freeze

    def run
      result = execute(command, args: applicable_files)
      return :pass if result.success?

      result.stderr.scan(FILES_REGEX).flatten.
        map { |file| message(file) }
    end

    private

    def message(file)
      Overcommit::Hook::Message.new(:error, file, nil, file)
    end
  end
end
