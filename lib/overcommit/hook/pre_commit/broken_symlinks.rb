module Overcommit::Hook::PreCommit
  # Checks for broken symlinks.
  class BrokenSymlinks < Base
    def run
      broken_symlinks = applicable_files.
        select { |file| Overcommit::Utils.broken_symlink?(file) }

      if broken_symlinks.any?
        return :fail, "Broken symlinks detected:\n#{broken_symlinks.join("\n")}"
      end

      :pass
    end
  end
end
