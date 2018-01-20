module Overcommit::Hook::PreCommit
  # Runs `chamber sign --verify`.
  #
  # @see https://github.com/thekompanee/chamber/wiki/Git-Commit-Hooks#chamber-verification-pre-commit-hook
  # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
  class ChamberVerification < Base
    def run
      approver_name  = config.fetch('approver_name', 'your approver')
      approver_email = config['approver_email'] ? " (#{config['approver_email']})" : nil

      result = execute(command)

      return :pass if result.stdout.empty? && result.stderr.empty?
      return :pass if result.stderr =~ /no signature key was found/

      output = [
        result.stdout.empty? ? nil : result.stdout,
        result.stderr.empty? ? nil : result.stderr,
      ].
        compact.
        join("\n\n")

      output = "\n\n#{output}" unless output.empty?

      [
        :warn,
        "One or more of your settings files does not match the signature.\n" \
        "Talk to #{approver_name}#{approver_email} about getting them " \
        "approved.#{output}",
      ]
    end
  end
  # rubocop:enable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
end
