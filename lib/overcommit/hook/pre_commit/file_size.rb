# frozen_string_literal: true

module Overcommit::Hook::PreCommit
  # Checks for oversized files before committing.
  class FileSize < Base
    def run
      return :pass if oversized_files.empty?

      oversized_files.map do |file|
        error_message_for(file)
      end
    end

    def description
      "Check for files over #{size_limit_bytes} bytes"
    end

    private

    def oversized_files
      @oversized_files ||= build_oversized_file_list
    end

    def build_oversized_file_list
      applicable_files.select do |file|
        file_size(file) > size_limit_bytes
      end
    end

    def size_limit_bytes
      config.fetch('size_limit_bytes')
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
      error_text_format % {
        path: relative_path_for(file),
        limit: size_limit_bytes,
        size: file_size(file)
      }
    end

    def error_text_format
      '%<path>s is over the file size limit of %<limit>s bytes (is %<size>s bytes)'
    end

    def file_size(file)
      File.size(file)
    end

    def relative_path_for(file)
      Pathname.new(file).relative_path_from(repo_root_path)
    end

    def repo_root_path
      @repo_root_path ||= Pathname.new(Overcommit::Utils.repo_root)
    end
  end
end
