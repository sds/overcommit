module Overcommit::Hook::PrePush
  # Prevents destructive updates to specified branches.
  class ProtectedBranches < Base
    def run
      return :pass unless illegal_pushes.any?

      messages = illegal_pushes.map do |pushed_ref|
        "Deleting or force-pushing to #{pushed_ref.remote_ref} is not allowed."
      end

      [:fail, messages.join("\n")]
    end

    private

    def illegal_pushes
      @illegal_pushes ||= pushed_refs.select do |pushed_ref|
        protected?(pushed_ref.remote_ref) && pushed_ref.destructive?
      end
    end

    def protected?(remote_ref)
      ref_name = remote_ref[%r{refs/heads/(.*)}, 1]
      protected_branch_patterns.any? do |pattern|
        File.fnmatch(pattern, ref_name)
      end
    end

    def protected_branch_patterns
      @protected_branch_patterns ||= Array(config['branches']).
        concat(Array(config['branch_patterns']))
    end
  end
end
