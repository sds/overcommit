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
        protected?(pushed_ref.remote_ref) && allow_non_destructive?(pushed_ref)
      end
    end

    def protected?(remote_ref)
      ref_name = remote_ref[%r{refs/heads/(.*)}, 1]
      return false if ref_name.nil?
      protected_branch_patterns.any? do |pattern|
        File.fnmatch(pattern, ref_name)
      end
    end

    def protected_branch_patterns
      @protected_branch_patterns ||= Array(config['branches']).
        concat(Array(config['branch_patterns']))
    end

    def destructive_only?
      config['destructive_only'].nil? || config['destructive_only']
    end

    def allow_non_destructive?(ref)
      if destructive_only?
        ref.destructive?
      else
        true
      end
    end
  end
end
