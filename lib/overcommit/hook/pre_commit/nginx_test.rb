module Overcommit::Hook::PreCommit
  # Runs `nginx -t` against any modified Nginx config files.
  #
  # @see https://www.nginx.com/resources/wiki/start/topics/tutorials/commandline/
  class NginxTest < Base
    MESSAGE_REGEX = /^nginx: .+ in (?<file>.+):(?<line>\d+)$/

    def run
      messages = []

      applicable_files.each do |file|
        result = execute(command + ['-c', file])
        next if result.success?

        messages += extract_messages(
          result.stderr.split("\n").grep(MESSAGE_REGEX),
          MESSAGE_REGEX
        )
      end

      messages
    end
  end
end
