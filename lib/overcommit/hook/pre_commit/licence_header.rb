module Overcommit::Hook::PreCommit
  # Checks for licence headers in source files
  class LicenceHeader < Base
    def run
      begin
        licence_contents = licence_lines
      rescue Errno::ENOENT
        return :fail, "Unable to load licence file #{licence_file}"
      end

      messages = applicable_files.map do |file|
        check_file(file, licence_contents)
      end.compact

      return :fail, messages.join("\n") if messages.any?

      :pass
    end

    def check_file(file, licence_contents)
      File.readlines(file).each_with_index do |l, i|
        if i >= licence_contents.length
          break
        end

        l.chomp!
        unless l.end_with?(licence_contents[i])
          message = "#{file} missing header contents from line #{i} of "\
                    "#{licence_file}: #{licence_contents[i]}"
          return message
        end
      end
    end

    def licence_file
      config['licence_file']
    end

    def licence_lines
      @licence_regex ||= begin
        file_root = Overcommit::Utils.convert_glob_to_absolute(licence_file)
        File.read(file_root).split("\n")
      end
    end
  end
end
