module Overcommit::Hook::PreCommit
  # Runs `chamber compare` against a configurable set of namespaces.
  #
  # @see https://github.com/thekompanee/chamber/wiki/Git-Commit-Hooks#chamber-compare-pre-commit-hook
  # rubocop:disable Metrics/MethodLength
  class ChamberCompare < Base
    def run
      config['namespaces'].each_index do |index|
        first  = config['namespaces'][index]
        second = config['namespaces'][index + 1]

        next unless second

        result = execute(
                   command,
                   args: [
                           "--first=#{first.join(' ')}",
                           "--second=#{second.join(' ')}",
                         ],
                 )

        unless result.stdout.empty?
          trimmed_result = result.stdout.split("\n")
          5.times { trimmed_result.shift }
          trimmed_result = trimmed_result.join("\n")

          return [
                   :warn,
                   "It appears your namespace settings between #{first} and " \
                   "#{second} are not in sync:\n\n#{trimmed_result}\n\n" \
                   "Run: chamber compare --first=#{first.join(' ')} " \
                   "--second=#{second.join(' ')}",
                 ]
        end
      end

      :pass
    end
  end
  # rubocop:enable Metrics/MethodLength
end
