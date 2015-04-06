module Overcommit::Hook::PostCheckout
  # Checks the status of submodules in the current repository and
  # notifies the user if any are uninitialized, out of date with
  # the current index, or contain merge conflicts.
  class SubmoduleStatus < Base
    SUBMODULE_STATUS_REGEX = /
      ^\s*(?<prefix>[-+U]?)(?<sha1>\w+)
      \s(?<path>[^\s]+?)
      (?:\s\((?<describe>.+)\))?$
    /x

    SubmoduleStatus = Struct.new(:prefix, :sha1, :path, :describe) do
      def uninitialized?
        prefix == '-'
      end

      def outdated?
        prefix == '+'
      end

      def merge_conflict?
        prefix == 'U'
      end
    end

    def run
      result = execute(command)
      submodule_statuses = parse_submodule_statuses(result.stdout)

      messages = []
      submodule_statuses.each do |submodule_status|
        path = submodule_status.path
        if submodule_status.uninitialized?
          messages << "Submodule #{path} is uninitialized."
        elsif submodule_status.outdated?
          messages << "Submodule #{path} is out of date with the current index."
        elsif submodule_status.merge_conflict?
          messages << "Submodule #{path} has merge conflicts."
        end
      end

      return :pass if messages.empty?

      [:warn, messages.join("\n")]
    end

    private

    def parse_submodule_statuses(output)
      output.scan(SUBMODULE_STATUS_REGEX).map do |prefix, sha1, path, describe|
        SubmoduleStatus.new(prefix, sha1, path, describe)
      end
    end
  end
end
