module Overcommit::HookContext
  # Contains helpers related to contextual information used by pre-commit hooks.
  #
  # This includes staged files, which lines of those files have been modified,
  # etc.
  class PreCommit < Base
    # Returns the set of line numbers corresponding to the lines that were
    # changed in a specified file.
    def modified_lines(staged_file)
      @modified_lines ||= {}
      @modified_lines[staged_file] ||= extract_modified_lines(staged_file)
    end

  private

    DIFF_HUNK_REGEX = /
      ^@@\s
      [^\s]+\s           # Ignore old file range
      \+(\d+)(?:,(\d+))? # Extract range of hunk containing start line and number of lines
      \s@@.*$
    /x

    def extract_modified_lines(staged_file)
      lines = Set.new

      `git diff --no-ext-diff --cached -U0 -- #{staged_file}`.
        scan(DIFF_HUNK_REGEX) do |start_line, lines_added|

        lines_added = (lines_added || 1).to_i # When blank, one line was added
        cur_line    = start_line.to_i

        lines_added.times do
          lines.add cur_line
          cur_line += 1
        end
      end

      lines
    end
  end
end
