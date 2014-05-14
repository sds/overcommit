require 'set'

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
  class Base
    def initialize(config, args, input)
      @config = config
      @args = args
      @input = input
    end

    # Returns the camel-cased type of this hook (e.g. PreCommit)
    def hook_class_name
      self.class.name.split('::').last
    end

    # Returns the snake-cased type of this hook (e.g. pre_commit)
    def hook_type_name
      Overcommit::Utils.snake_case(hook_class_name)
    end

    # Returns the actual name of the hook script being run (e.g. pre-commit).
    def hook_script_name
      hook_type_name.gsub('_', '-')
    end

    # Initializes anything related to the environment.
    #
    # This is called before the hooks are run by the [HookRunner]. Different
    # hook types can perform different setup.
    def setup_environment
      # Implemented by subclass
    end

    # Resets the environment to an appropriate state.
    #
    # This is called after the hooks have been run by the [HookRunner].
    # Different hook types can perform different cleanup operations, which are
    # intended to "undo" the results of the call to {#setup_environment}.
    def cleanup_environment
      # Implemented by subclass
    end

    # Returns a list of files that have been modified.
    #
    # By default, this returns an empty list. Subclasses should implement if
    # there is a concept of files changing for the type of hook being run.
    def modified_files
      []
    end

    # Returns a set of lines that have been modified for a file.
    #
    # By default, this returns an empty set. Subclasses should implement if
    # there is a concept of files changing for the type of hook being run.
    def modified_lines(_file)
      Set.new
    end
  end
end
