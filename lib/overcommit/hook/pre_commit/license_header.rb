module Overcommit::Hook::PreCommit
  # Checks for license headers in source files
  class LicenseHeader < Base
    def run
      begin
        license_contents = license_lines
      rescue Errno::ENOENT
        return :fail, "Unable to load license file #{license_file}"
      end

      messages = applicable_files.map do |file|
        check_file(file, license_contents)
      end.compact

      return :fail, messages.join("\n") if messages.any?

      :pass
    end

    def check_file(file, license_contents)
      File.readlines(file).each_with_index do |l, i|
        if i >= license_contents.length
          break
        end

        l.chomp!
        unless l.end_with?(license_contents[i])
          message = "#{file} missing header contents from line #{i} of "\
                    "#{license_file}: #{license_contents[i]}"
          return message
        end
      end
    end

    def license_file
      config['license_file']
    end

    def license_lines
      @license_regex ||= begin
        file_root = Overcommit::Utils.convert_glob_to_absolute(license_file)
        File.read(file_root).split("\n")
      end
    end
  end
end
