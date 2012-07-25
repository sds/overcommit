module Causes
  module GitHook
    module FileMethods
      def modified_files(type=nil, path=nil)
        @modified_files ||=
          `git diff --cached --name-only --diff-filter=ACM -- #{path}`.split "\n"
        type ? @modified_files.select { |f| f =~ /\.#{type}$/ } : @modified_files
      end

      def staged_files(*args)
        modified_files(*args).map { |filename| StagedFile.new(filename) }
      end

      def in_path?(cmd)
        system("which #{cmd} &> /dev/null")
      end
    end
  end
end
