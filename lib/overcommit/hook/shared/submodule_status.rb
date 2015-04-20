module Overcommit::Hook::Shared
  # Shared code used by all `SubmoduleStatus` hooks to notify the user if any
  # submodules are uninitialized, out of date with the current index, or contain
  # merge conflicts.
  module SubmoduleStatus
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
