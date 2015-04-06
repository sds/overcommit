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

    def branches
      @branches ||= config['branches']
    end

    def illegal_pushes
      @illegal_pushes ||= pushed_refs.select do |pushed_ref|
        (pushed_ref.deleted? || pushed_ref.forced?) &&
          branches.any? { |branch| pushed_ref.remote_ref == "refs/heads/#{branch}" }
      end
    end
  end
end
