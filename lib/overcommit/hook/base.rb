require 'forwardable'

module Overcommit::Hook
  # Functionality common to all hooks.
  class Base
    extend Forwardable

    def_delegators :@context, :modified_files

    def initialize(config, context)
      @config = config.for_hook(self)
      @context = context
    end

    # Runs the hook.
    def run
      raise NotImplementedError, 'Hook must define `run`'
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
                 includes.any? { |glob| Dir[glob].include?(file) }

      excludes = Array(@config['exclude']).map { |glob| convert_glob_to_absolute(glob) }
      excluded = excludes.any? { |glob| Dir[glob].include?(file) }

      included && !excluded
    end

    def convert_glob_to_absolute(glob)
      repo_root = Overcommit::Utils.repo_root
      File.join(repo_root, glob)
    end
  end
end
