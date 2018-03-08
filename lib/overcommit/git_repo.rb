require 'iniparse'

module Overcommit
  # Provide a set of utilities for certain interactions with `git`.
  module GitRepo
    module_function

    # Regular expression used to extract diff ranges from hunks of diff output.
    DIFF_HUNK_REGEX = /
      ^@@\s
      [^\s]+\s           # Ignore old file range
      \+(\d+)(?:,(\d+))? # Extract range of hunk containing start line and number of lines
      \s@@.*$
    /x

    # Regular expression used to extract information from lines of
    # `git submodule status` output
    SUBMODULE_STATUS_REGEX = /
      ^\s*(?<prefix>[-+U]?)(?<sha1>\w+)
      \s(?<path>[^\s]+?)
      (?:\s\((?<describe>.+)\))?$
    /x

    # Struct encapsulating submodule information extracted from the
    # output of `git submodule status`
    SubmoduleStatus = Struct.new(:prefix, :sha1, :path, :describe) do
      # Returns whether the submodule has not been initialized
      def uninitialized?
        prefix == '-'
      end

      # Returns whether the submodule is out of date with the current
      # index, i.e. its checked-out commit differs from that stored in
      # the index of the parent repo
      def outdated?
        prefix == '+'
      end

      # Returns whether the submodule reference has a merge conflict
      def merge_conflict?
        prefix == 'U'
      end
    end

    # Returns a list of SubmoduleStatus objects, one for each submodule in the
    # parent repository.
    #
    # @option options [Boolean] recursive check submodules recursively
    # @return [Array<SubmoduleStatus>]
    def submodule_statuses(options = {})
      flags = '--recursive' if options[:recursive]

      `git submodule status #{flags}`.
        scan(SUBMODULE_STATUS_REGEX).
        map do |prefix, sha1, path, describe|
          SubmoduleStatus.new(prefix, sha1, path, describe)
        end
    end

    # Extract the set of modified lines from a given file.
    #
    # @param file_path [String]
    # @param options [Hash]
    # @return [Set] line numbers that have been modified in file
    def extract_modified_lines(file_path, options)
      lines = Set.new

      flags = '--cached' if options[:staged]
      refs = options[:refs]
      subcmd = options[:subcmd] || 'diff'

      `git #{subcmd} --no-color --no-ext-diff -U0 #{flags} #{refs} -- "#{file_path}"`.
        scan(DIFF_HUNK_REGEX) do |start_line, lines_added|
        lines_added = (lines_added || 1).to_i # When blank, one line was added
        cur_line = start_line.to_i

        lines_added.times do
          lines.add cur_line
          cur_line += 1
        end
      end

      lines
    end

    # Returns the names of all files that have been modified compared to HEAD.
    #
    # @param options [Hash]
    # @return [Array<String>] list of absolute file paths
    def modified_files(options)
      flags = '--cached' if options[:staged]
      refs = options[:refs]
      subcmd = options[:subcmd] || 'diff'

      `git #{subcmd} --name-only -z --diff-filter=ACMR --ignore-submodules=all #{flags} #{refs}`.
        split("\0").
        map(&:strip).
        reject(&:empty?).
        map { |relative_file| File.expand_path(relative_file) }
    end

    # Returns the names of files in the given paths that are tracked by git.
    #
    # @param paths [Array<String>] list of paths to check
    # @option options [String] ref ('HEAD') Git ref to check
    # @return [Array<String>] list of absolute file paths
    def list_files(paths = [], options = {})
      ref = options[:ref] || 'HEAD'
      path_list = paths.empty? ? '' : "\"#{paths.join('" "')}\""
      `git ls-tree --name-only #{ref} #{path_list}`.
        split(/\n/).
        map { |relative_file| File.expand_path(relative_file) }.
        reject { |file| File.directory?(file) } # Exclude submodule directories
    end

    # Returns whether the specified file/path is tracked by this repository.
    #
    # @param path [String]
    # @return [true,false]
    def tracked?(path)
      Overcommit::Utils.execute(%W[git ls-files #{path} --error-unmatch]).success?
    end

    # Returns the names of all files that are tracked by git.
    #
    # @return [Array<String>] list of absolute file paths
    def all_files
      `git ls-files`.
        split(/\n/).
        map { |relative_file| File.expand_path(relative_file) }.
        reject { |file| File.directory?(file) } # Exclude submodule directories
    end

    # Returns whether the current git branch is empty (has no commits).
    # @return [true,false]
    def initial_commit?
      !Overcommit::Utils.execute(%w[git rev-parse HEAD]).success?
    end

    # Store any relevant files that are present when repo is in the middle of a
    # merge.
    #
    # Restored via [#restore_merge_state].
    def store_merge_state
      merge_head = `git rev-parse MERGE_HEAD 2> #{File::NULL}`.chomp

      # Store the merge state if we're in the middle of resolving a merge
      # conflict. This is necessary since stashing removes the merge state.
      if merge_head != 'MERGE_HEAD'
        @merge_head = merge_head
      end

      merge_msg_file = File.expand_path('MERGE_MSG', Overcommit::Utils.git_dir)
      @merge_msg = File.open(merge_msg_file).read if File.exist?(merge_msg_file)
    end

    # Store any relevant files that are present when repo is in the middle of a
    # cherry-pick.
    #
    # Restored via [#restore_cherry_pick_state].
    def store_cherry_pick_state
      cherry_head = `git rev-parse CHERRY_PICK_HEAD 2> #{File::NULL}`.chomp

      # Store the merge state if we're in the middle of resolving a merge
      # conflict. This is necessary since stashing removes the merge state.
      if cherry_head != 'CHERRY_PICK_HEAD'
        @cherry_head = cherry_head
      end
    end

    # Restore any relevant files that were present when repo was in the middle
    # of a merge.
    def restore_merge_state
      if @merge_head
        FileUtils.touch(File.expand_path('MERGE_MODE', Overcommit::Utils.git_dir))

        File.open(File.expand_path('MERGE_HEAD', Overcommit::Utils.git_dir), 'w') do |f|
          f.write(@merge_head)
        end
        @merge_head = nil
      end

      if @merge_msg
        File.open(File.expand_path('MERGE_MSG', Overcommit::Utils.git_dir), 'w') do |f|
          f.write("#{@merge_msg}\n")
        end
        @merge_msg = nil
      end
    end

    # Restore any relevant files that were present when repo was in the middle
    # of a cherry-pick.
    def restore_cherry_pick_state
      if @cherry_head
        File.open(File.expand_path('CHERRY_PICK_HEAD',
                                   Overcommit::Utils.git_dir), 'w') do |f|
          f.write(@cherry_head)
        end
        @cherry_head = nil
      end
    end

    # Contains information about a registered submodule.
    Submodule = Struct.new(:path, :url)

    # Returns the submodules that have been staged for removal.
    #
    # `git` has an unexpected behavior where removing a submodule without
    # committing (i.e. such that the submodule directory is removed and the
    # changes to the index are staged) and then doing a hard reset results in
    # the index being wiped but the empty directory of the once existent
    # submodule being restored (but with no content).
    #
    # This prevents restoration of the stash of the submodule index changes,
    # which breaks pre-commit hook restorations of the working index.
    #
    # Thus we expose this helper so the restoration code can manually delete the
    # directory.
    #
    # @raise [Overcommit::Exceptions::GitSubmoduleError] when
    def staged_submodule_removals
      # There were no submodules before, so none could have been removed
      return [] if `git ls-files .gitmodules`.empty?

      previous = submodules(ref: 'HEAD')
      current = submodules

      previous - current
    end

    # Returns the current set of registered submodules.
    #
    # @param options [Hash]
    # @return [Array<Overcommit::GitRepo::Submodule>]
    def submodules(options = {})
      ref = options[:ref]

      modules = []
      IniParse.parse(`git show #{ref}:.gitmodules 2> #{File::NULL}`).each do |section|
        # git < 1.8.5 does not update the .gitmodules file with submodule
        # changes, so when we are looking at the current state of the work tree,
        # we need to check if the submodule actually exists via another method,
        # since the .gitmodules file we parsed does not represent reality.
        if ref.nil? && GIT_VERSION < '1.8.5'
          result = Overcommit::Utils.execute(%W[
            git submodule status #{section['path']}
          ])
          next unless result.success?
        end

        modules << Submodule.new(section['path'], section['url'])
      end

      modules
    rescue IniParse::IniParseError => ex
      raise Overcommit::Exceptions::GitSubmoduleError,
            "Unable to read submodule information from #{ref}:.gitmodules file: #{ex.message}"
    end

    # Returns the names of all branches containing the given commit.
    #
    # @param commit_ref [String] git tree ref that resolves to a commit
    # @return [Array<String>] list of branches containing the given commit
    def branches_containing_commit(commit_ref)
      `git branch --column=dense --contains #{commit_ref}`.
        sub(/\((HEAD )?detached (from|at) .*?\)/, ''). # ignore detached HEAD
        split(/\s+/).
        reject { |s| s.empty? || s == '*' }
    end

    # Returns the name of the currently checked out branch.
    # @return [String]
    def current_branch
      `git symbolic-ref --short -q HEAD`.chomp
    end
  end
end
