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

    def modified_files
      @modified_files ||= pushed_refs.map(&:modified_files).flatten.uniq
    end

    def modified_lines_in_file(file)
      @modified_lines ||= {}
      @modified_lines[file] = pushed_refs.each_with_object(Set.new) do |pushed_ref, set|
        set.merge(pushed_ref.modified_lines_in_file(file))
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

      def modified_files
        Overcommit::GitRepo.modified_files(refs: ref_range)
      end

      def modified_lines_in_file(file)
        Overcommit::GitRepo.extract_modified_lines(file, refs: ref_range)
      end

      def to_s
        "#{local_ref} #{local_sha1} #{remote_ref} #{remote_sha1}"
      end

      private

      def ref_range
        "#{remote_sha1}..#{local_sha1}"
      end

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
