module Overcommit::Hook::PostCheckout
  # Checks the status of submodules in the current repository and
  # notifies the user if any are uninitialized, out of date with
  # the current index, or contain merge conflicts.
  class SubmoduleStatus < Base
    def run
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

    def submodule_statuses
      Overcommit::GitRepo.submodule_statuses(recursive: config['recursive'])
    end
  end
end
