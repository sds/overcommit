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

    # Extract the set of modified lines from a given file.
    #
    # @param file_path [String]
    # @param options [Hash]
    # @return [Set] line numbers that have been modified in file
    def extract_modified_lines(file_path, options)
      lines = Set.new

      flags = '--cached' if options[:staged]

      `git diff --no-ext-diff -U0 #{flags} -- #{file_path}`.
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

    # Returns the names of all files that have been modified from compared to
    # HEAD.
    #
    # @param options [Hash]
    # @return [Array<String>] list of absolute file paths
    def modified_files(options)
      flags = '--cached' if options[:staged]

      `git diff --name-only -z --diff-filter=ACM --ignore-submodules=all #{flags}`.
        split("\0").
        map { |relative_file| File.expand_path(relative_file) }
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
      merge_head = `git rev-parse MERGE_HEAD 2> /dev/null`.chomp

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
      cherry_head = `git rev-parse CHERRY_PICK_HEAD 2> /dev/null`.chomp

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
          f.write("#{@merge_head}\n")
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
          f.write("#{@cherry_head}\n")
        end
        @cherry_head = nil
      end
    end
  end
end
