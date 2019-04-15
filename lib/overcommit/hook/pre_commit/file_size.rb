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
        File.exist?(file) && file_size(file) > size_limit_bytes
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
        "#{file} is #{file_size(file)} bytes"
      )
    end

    def file_size(file)
      File.size(file)
    end
  end
end
