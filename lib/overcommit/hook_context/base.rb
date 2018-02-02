module Overcommit::HookContext
  # Contains helpers related to the context with which a hook is being run.
  #
  # It acts as an adapter to the arguments passed to the hook, as well as
  # context-specific information such as staged files, providing a single source
  # of truth for this context.
  #
  # This is also important to house in a separate object so that any
  # calculations can be memoized across all hooks in a single object, which
  # helps with performance.
  #
  # @abstract
  class Base
    # Creates a hook context from the given configuration and input options.
    #
    # @param config [Overcommit::Configuration]
    # @param args [Array<String>]
    # @param input [IO] standard input stream
    def initialize(config, args, input)
      @config = config
      @args = args
      @input = input
    end

    # Executes a command as if it were a regular git hook, passing all
    # command-line arguments and the standard input stream.
    #
    # This is intended to be used by ad hoc hooks so developers can link up
    # their existing git hooks with Overcommit.
    def execute_hook(command)
      Overcommit::Utils.execute(command, args: @args, input: input_string)
    end

    # Returns the camel-cased type of this hook (e.g. PreCommit)
    #
    # @return [String]
    def hook_class_name
      self.class.name.split('::').last
    end

    # Returns the snake-cased type of this hook (e.g. pre_commit)
    #
    # @return [String]
    def hook_type_name
      Overcommit::Utils.snake_case(hook_class_name)
    end

    # Returns the actual name of the hook script being run (e.g. pre-commit).
    #
    # @return [String]
    def hook_script_name
      hook_type_name.tr('_', '-')
    end

    # Initializes anything related to the environment.
    #
    # This is called before the hooks are run by the [HookRunner]. Different
    # hook types can perform different setup.
    def setup_environment
      # Implemented by subclass, if applicable
    end

    # Resets the environment to an appropriate state.
    #
    # This is called after the hooks have been run by the [HookRunner].
    # Different hook types can perform different cleanup operations, which are
    # intended to "undo" the results of the call to {#setup_environment}.
    def cleanup_environment
      # Implemented by subclass, if applicable
    end

    # Returns a list of files that have been modified.
    #
    # By default, this returns an empty list. Subclasses should implement if
    # there is a concept of files changing for the type of hook being run.
    #
    # @return [Array<String>]
    def modified_files
      []
    end

    # Returns the full list of files tracked by git
    #
    # @return [Array<String>]
    def all_files
      Overcommit::GitRepo.all_files
    end

    # Returns the contents of the entire standard input stream that were passed
    # to the hook.
    #
    # @return [String]
    def input_string
      @input_string ||= @input.read
    end

    # Returns an array of lines passed to the hook via the standard input
    # stream.
    #
    # @return [Array<String>]
    def input_lines
      @input_lines ||= input_string.split("\n")
    end

    # Returns a message to display on failure.
    #
    # @return [String]
    def post_fail_message
      nil
    end

    private

    def filter_modified_files(modified_files)
      filter_directories(filter_nonexistent(modified_files))
    end

    # Filter out non-existent files (unless it's a broken symlink, in which case
    # it's a file that points to a non-existent file). This could happen if a
    # file was renamed as part of an amendment, leading to the old file no
    # longer existing.
    def filter_nonexistent(modified_files)
      modified_files.select do |file|
        File.exist?(file) || Overcommit::Utils.broken_symlink?(file)
      end
    end

    # Filter out directories. This could happen when changing a symlink to a
    # directory as part of an amendment, since the symlink will still appear as
    # a file, but the actual working tree will have a directory.
    def filter_directories(modified_files)
      modified_files.reject do |file|
        File.directory?(file) && !Overcommit::Utils::FileUtils.symlink?(file)
      end
    end
  end
end
