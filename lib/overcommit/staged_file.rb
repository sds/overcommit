# We run syntax checks against the version of the file that is staged in
# the index, not the one in the work tree. This class is a simple wrapper
# to make working with staged files easier.

module Overcommit
  class StagedFile
    attr_reader :contents

    def initialize path
      @original_path  = path
      @tempfile       = Tempfile.new([path.gsub('/', '_'), File.extname(path)])
      self.contents   = `git show :#{@original_path}`
    end

    # Given error output from a syntax checker, replace references to the
    # temporary file path with the original path.
    def filter_string string
      string.gsub(path, @original_path)
    end

    # The path of the temporary file on disk, suitable for feeding in to a
    # syntax checker.
    def path
      @tempfile.path
    end

    # Set or overwrite the temporary file's contents.
    #
    # This is used by the ERB syntax checker, for example, to compile
    # the template before checking.
    def contents=(contents)
      @contents = contents
      @tempfile.seek 0
      @tempfile.write @contents
      @tempfile.flush
    end
  end
end
