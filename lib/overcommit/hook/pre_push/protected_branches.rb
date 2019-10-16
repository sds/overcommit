# frozen_string_literal: true

module Overcommit::Hook::PrePush
  # Prevents updates to specified branches.
  # Accepts a 'destructive_only' option globally or per branch
  # to only prevent destructive updates.
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
        protected?(pushed_ref)
      end
    end

    def protected?(ref)
      find_pattern(ref.remote_ref)&.destructive?(ref)
    end

    def find_pattern(remote_ref)
      ref_name = remote_ref[%r{refs/heads/(.*)}, 1]
      return if ref_name.nil?

      patterns.find do |pattern|
        File.fnmatch(pattern.to_s, ref_name)
      end
    end

    def patterns
      @patterns ||= fetch_patterns
    end

    def fetch_patterns
      branch_configurations.map do |pattern|
        if pattern.is_a?(Hash)
          Pattern.new(pattern.keys.first, pattern['destructive_only'])
        else
          Pattern.new(pattern, global_destructive_only?)
        end
      end
    end

    def branch_configurations
      config['branches'].to_a + config['branch_patterns'].to_a
    end

    def global_destructive_only?
      config['destructive_only'].nil? || config['destructive_only']
    end

    Pattern = Struct.new('Pattern', :name, :destructive_only) do
      alias_method :to_s, :name
      alias_method :destructive_only?, :destructive_only

      def destructive?(ref)
        if destructive_only?
          ref.destructive?
        else
          true
        end
      end
    end
  end
end
