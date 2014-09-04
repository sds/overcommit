require 'forwardable'

module Overcommit::Hook
  # Functionality common to all hooks.
  class Base
    extend Forwardable

    def_delegators :@context, :modified_files
    attr_reader :config

    def initialize(config, context)
      @config = config.for_hook(self)
      @context = context
    end

    # Runs the hook.
    def run
      raise NotImplementedError, 'Hook must define `run`'
    end

    # Runs the hook and transforms the status returned based on the hook's
    # configuration.
    #
    # Poorly named because we already have a bunch of hooks in the wild that
    # implement `#run`, and we needed a wrapper step to transform the status
    # based on any custom configuration.
    def run_and_transform
      status, output = run

      [transform_status(status), output]
    end

    def name
      self.class.name.split('::').last
    end

    def description
      @config['description'] || "Running #{name}"
    end

    def required?
      @config['required']
    end

    def quiet?
      @config['quiet']
    end

    def enabled?
      @config['enabled'] != false
    end

    def skip?
      @config['skip']
    end

    def run?
      enabled? &&
        (!skip? || required?) &&
        !(requires_modified_files? && applicable_files.empty?)
    end

    def in_path?(cmd)
      Overcommit::Utils.in_path?(cmd)
    end

    def execute(cmd)
      Overcommit::Utils.execute(cmd)
    end

    # Gets a list of staged files that apply to this hook based on its
    # configured `include` and `exclude` lists.
    def applicable_files
      @applicable_files ||= modified_files.select { |file| applicable_file?(file) }
    end

    private

    def requires_modified_files?
      @config['requires_files']
    end

    def applicable_file?(file)
      includes = Array(@config['include']).map { |glob| convert_glob_to_absolute(glob) }
      included = includes.empty? ||
                 includes.any? { |glob| matches_path?(glob, file) }

      excludes = Array(@config['exclude']).map { |glob| convert_glob_to_absolute(glob) }
      excluded = excludes.any? { |glob| matches_path?(glob, file) }

      included && !excluded
    end

    def convert_glob_to_absolute(glob)
      repo_root = Overcommit::Utils.repo_root
      File.join(repo_root, glob)
    end

    # Return whether a pattern matches the given path.
    #
    # @param pattern [String]
    # @param path [String]
    def matches_path?(pattern, path)
      File.fnmatch?(pattern, path,
                    File::FNM_PATHNAME | # Wildcard doesn't match separator
                    File::FNM_DOTMATCH   # Wildcards match dotfiles
      )
    end

    # Transforms the hook's status based on custom configuration.
    #
    # This allows users to change failures into warnings, or vice versa.
    def transform_status(status)
      case status
      when :fail, :bad
        @config.fetch('on_fail', :fail).to_sym
      when :warn
        @config.fetch('on_warn', :warn).to_sym
      else
        status
      end
    end
  end
end
