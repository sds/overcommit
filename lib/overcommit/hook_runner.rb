# encoding: utf-8

module Overcommit
  # Responsible for loading the hooks the repository has configured and running
  # them, collecting and displaying the results.
  class HookRunner
    def initialize(config, logger, context)
      @config = config
      @log = logger
      @context = context
      @hooks = []
    end

    # Loads and runs the hooks registered for this {HookRunner}.
    def run
      load_hooks
      @context.setup_environment
      run_hooks
    ensure
      @context.cleanup_environment
    end

  private

    attr_reader :log

    def run_hooks
      if @hooks.any? { |hook| hook.run? || hook.skip? }
        log.bold "Running #{@context.hook_script_name} hooks"

        statuses = @hooks.map { |hook| run_hook(hook) }.compact

        log.log # Newline

        run_failed = statuses.include?(:bad)

        if run_failed
          log.error "✗ One or more #{@context.hook_script_name} hooks failed"
        else
          log.success "✓ All #{@context.hook_script_name} hooks passed"
        end

        log.log # Newline

        !run_failed
      else
        log.success "✓ No applicable #{@context.hook_script_name} hooks to run"
        true # Run was successful
      end
    end

    def run_hook(hook)
      return unless hook.enabled?

      if hook.skip?
        if hook.required?
          log.warning "Cannot skip #{hook.name} since it is required"
        else
          log.warning "Skipping #{hook.name}"
          return
        end
      end

      return unless hook.run?

      unless hook.quiet?
        print_header(hook)
      end

      begin
        status, output = hook.run
      rescue => ex
        status = :bad
        output = "Hook raised unexpected error\n#{ex.message}"
      end

      # Want to print the header in the event the result wasn't good so that the
      # user knows what failed
      if hook.quiet? && status != :good
        print_header(hook)
      end

      case status
      when :good
        log.success 'OK' unless hook.quiet?
      when :warn
        log.warning 'WARNING'
        print_report(output, :bold_warning)
      when :bad
        log.error 'FAILED'
        print_report(output, :bold_error)
      end

      status
    end

    def print_header(hook)
      log.partial hook.description
      log.partial '.' * (70 - hook.description.length)
    end

    def print_report(output, format = :log)
      log.send(format, output) unless output.empty?
    end

    # Loads hooks that will be run.
    # This is done explicitly so that we only load hooks which will actually be
    # used.
    def load_hooks
      require "overcommit/hook/#{@context.hook_type_name}/base"

      load_builtin_hooks
      load_hook_plugins # Load after so they can subclass/modify existing hooks
    end

    # Load hooks that ship with Overcommit, ignoring ones that are excluded from
    # the repository's configuration.
    def load_builtin_hooks
      @config.enabled_builtin_hooks(@context.hook_class_name).each do |hook_name|
        underscored_hook_name = Overcommit::Utils.snake_case(hook_name)
        require "overcommit/hook/#{@context.hook_type_name}/#{underscored_hook_name}"
        @hooks << create_hook(hook_name)
      end
    end

    # Load hooks that are stored in the repository's plugin directory.
    def load_hook_plugins
      directory = File.join(@config.plugin_directory, @context.hook_type_name)

      Dir[File.join(directory, '*.rb')].sort.each do |plugin|
        require plugin

        hook_name = Overcommit::Utils.camel_case(File.basename(plugin, '.rb'))
        @hooks << create_hook(hook_name)
      end
    end

    # Load and return a {Hook} from a CamelCase hook name and the given
    # hook configuration.
    def create_hook(hook_name)
      Overcommit::Hook.const_get(@context.hook_class_name).
                       const_get(hook_name).
                       new(@config, @context)
    rescue LoadError, NameError => error
      raise Overcommit::Exceptions::HookLoadError,
            "Unable to load hook '#{hook_name}': #{error}",
            error.backtrace
    end
  end
end
