module Overcommit::HookContext
  # Contains helpers related to contextual information used by pre-push hooks.
  class PrePush < Base
    attr_accessor :args

    def remote_name
      @args[0]
    end

    def remote_url
      @args[1]
    end

    def pushed_refs
      input_lines.map do |line|
        PushedRef.new(*line.split(' '))
      end
    end

    PushedRef = Struct.new(:local_ref, :local_sha1, :remote_ref, :remote_sha1) do
      def forced?
        !(created? || deleted? || overwritten_commits.empty?)
      end

      def created?
        remote_sha1 == '0' * 40
      end

      def deleted?
        local_sha1 == '0' * 40
      end

      def destructive?
        deleted? || forced?
      end

      def to_s
        "#{local_ref} #{local_sha1} #{remote_ref} #{remote_sha1}"
      end

      private

      def overwritten_commits
        return @overwritten_commits if defined? @overwritten_commits
        result = Overcommit::Subprocess.spawn(%W[git rev-list #{remote_sha1} ^#{local_sha1}])
        if result.success?
          result.stdout.split("\n")
        else
          raise Overcommit::Exceptions::GitRevListError,
                "Unable to check if commits on the remote ref will be overwritten: #{result.stderr}"
        end
      end
    end
  end
end
