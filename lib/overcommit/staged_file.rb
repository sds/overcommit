require 'set'
require 'tempfile'

# We run syntax checks against the version of the file that is staged in
# the index, not the one in the work tree. This class is a simple wrapper
# to make working with staged files easier.
module Overcommit
  class StagedFile
    attr_reader :contents

    def initialize(path)
      @original_path = path
      @contents      = `git show :#{@original_path}`
    end

    # Given error output from a syntax checker, replace references to the
    # temporary file path with the original path.
    def filter_string(string)
      string.gsub(path, @original_path)
    end

    # The path of the temporary file on disk, suitable for feeding in to a
    # syntax checker.
    def path
      tempfile.path
    end

    # Set or overwrite the temporary file's contents.
    #
    # This is used by the ERB syntax checker, for example, to compile
    # the template before checking.
    def contents=(contents)
      @contents = contents
      write_tempfile
    end

    # Returns the set of line numbers corresponding to the lines that were
    # changed in this file.
    def modified_lines
      @modified_lines ||= extract_modified_lines
    end

  private

    DIFF_HUNK_REGEX = /
      ^@@\s
      [^\s]+\s           # Ignore old file range
      \+(\d+)(?:,(\d+))? # Extract range of hunk containing start line and number of lines
      \s@@.*$
    /x

    def extract_modified_lines
      lines = Set.new

      `git diff --no-ext-diff --cached -U0 -- #{@original_path}`.
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

    def tempfile
      unless @tempfile
        basename = [@original_path.gsub('/', '_'), File.extname(@original_path)]
        @tempfile = Tempfile.new(basename)
        write_tempfile
      end
      @tempfile
    end

    def write_tempfile
      tempfile.open if tempfile.closed?
      tempfile.truncate 0
      tempfile.write @contents
      tempfile.close
    end
  end
end
