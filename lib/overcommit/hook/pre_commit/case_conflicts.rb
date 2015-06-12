module Overcommit::Hook::PreCommit
  # Checks for files that would conflict in case-insensitive filesystems
  # Adapted from https://github.com/pre-commit/pre-commit-hooks
  class CaseConflicts < Base
    def run
      repo_files = Set.new(applicable_files)

      unless Overcommit::GitRepo.initial_commit?
        paths = repo_files.map { |file| File.dirname(file) + File::SEPARATOR }.uniq
        repo_files += Overcommit::GitRepo.list_files(paths)
      end

      conflict_hash = repo_files.classify(&:downcase).
        select { |_, files| files.size > 1 }
      conflict_files = applicable_files.
        select { |file| conflict_hash.include?(file.downcase) }

      conflict_files.map do |file|
        conflicts = conflict_hash[file.downcase].map { |f| File.basename(f) }
        msg = "Conflict detected for case-insensitive file systems: #{conflicts.join(', ')}"
        Overcommit::Hook::Message.new(:error, file, nil, msg)
      end
    end
  end
end
