module Overcommit::Hook::PreCommit
  class FileSize < Base
    DEFAULT_SIZE_LIMIT_BYTES = 1_000_000 # 1MB

    def run
      return :pass if oversized_files.empty?

      oversized_files.map do |file|
        error_message_for(file)
      end
    end

    private

      def oversized_files
        @_oversized_files ||= build_oversized_file_list
      end

      def build_oversized_file_list
        applicable_files.select do |file|
          file_size(file) > size_limit_bytes
        end
      end

      def size_limit_bytes
        config.fetch("size_limit_bytes", DEFAULT_SIZE_LIMIT_BYTES)
      end

      def error_message_for(file)
        Overcommit::Hook::Message.new(
          :error,
          file,
          nil,
          error_text_for(file)
        )
      end

      def error_text_for(file)
        "#{relative_path_for(file)} is over the file size limit of #{size_limit_bytes} bytes (is #{file_size(file)} bytes)"
      end

      def file_size(file)
        File.size(file)
      end

      def relative_path_for(file)
        Pathname.new(file).relative_path_from(repo_root_path)
      end

      def repo_root_path
        @_repo_root_path ||= Pathname.new(Overcommit::Utils.repo_root)
      end
  end
end
