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

    def hook_class_name
      @hook_class_name ||= self.class.name.split('::').last
    end

    # Get a list of added, copied, or modified files that have been staged.
    # Renames and deletions are ignored, since there should be nothing to check.
    def staged_files
      @staged_files ||=
        `git diff --cached --name-only --diff-filter=ACM --ignore-submodules=all`.
          split("\n").
          map { |relative_file| File.expand_path(relative_file) }
    end
  end
end
