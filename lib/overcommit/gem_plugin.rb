# frozen_string_literal: true

require 'digest'
require 'find'
require 'json'

module Overcommit
  # A gem source and its approval, resolved without requiring its entrypoint.
  class GemPlugin # rubocop:disable Metrics/ClassLength
    attr_reader :namespace, :hook_names

    def initialize(namespace, config, context)
      @namespace = namespace
      @config = config
      @context = context
      @gem_name = (config['gem_plugins'] || {})[namespace]
      unless @gem_name
        raise Overcommit::Exceptions::HookLoadError,
              "Declare the gem for #{namespace} in `gem_plugins`"
      end
      @hook_names = config.enabled_gem_hooks(context).
        select { |name| name.start_with?("#{namespace}::") }
    end

    def hook_name
      "#{namespace} (gem #{@gem_name})"
    end

    def hook_path
      specification.full_gem_path
    end

    def signature_verified?
      signature_store.include?(signature)
    end

    def update_signature!
      signature_store.add(signature)
    end

    # Resolve every hook before requiring any code, so a missing hook fails closed.
    def hook_paths
      hook_names.map do |name|
        relative = File.join('overcommit', 'hooks', @context.hook_type_name,
                             "#{Overcommit::Utils.snake_case(name.split('::').last)}.rb")
        paths = specification.require_paths.map do |root|
          File.expand_path(File.join(root, relative), hook_path)
        end
        path = paths.find { |candidate| File.file?(candidate) }
        path = File.realpath(path) if path
        unless path&.start_with?(File.realpath(hook_path) + File::SEPARATOR)
          raise Overcommit::Exceptions::HookLoadError,
                "Gem #{@gem_name} does not provide #{name} at #{relative}"
        end
        path
      end
    end

    def activate
      specifications.reverse_each(&:activate)
    rescue Gem::LoadError => e
      raise Overcommit::Exceptions::HookLoadError, "Unable to activate #{@gem_name}: #{e.message}"
    end

    private

    def specification
      @specification ||= find_specification(@gem_name)
    end

    def find_specification(name, requirement = Gem::Requirement.default)
      spec = Gem.loaded_specs[name] || Gem::Specification.find_by_name(name, requirement)
      unless requirement.satisfied_by?(spec.version)
        raise Gem::LoadError, "#{name} #{spec.version} does not satisfy #{requirement}"
      end

      spec
    rescue Gem::LoadError => e
      raise Overcommit::Exceptions::HookLoadError,
            "Unable to resolve gem plugin #{@gem_name}: #{e.message}. " \
            'Install the gem and its dependencies; include them in your Gemfile when using Bundler.'
    end

    def specifications
      @specifications ||= collect_specifications(specification, {}).values.sort_by(&:name)
    end

    def collect_specifications(spec, found)
      if found.key?(spec.name)
        unless found[spec.name].version == spec.version
          raise Overcommit::Exceptions::HookLoadError, "Conflicting versions of #{spec.name}"
        end

        return found
      end

      found[spec.name] = spec
      spec.runtime_dependencies.each do |dependency|
        # Overcommit itself is already running and trusted, like built-in hooks.
        next if dependency.name == 'overcommit'

        collect_specifications(find_specification(dependency.name, dependency.requirement), found)
      end
      found
    end

    def signature
      digest = Digest::SHA256.new
      settings = hook_names.sort.map do |name|
        hook_config = @config.for_hook(name, @context.hook_class_name).
          reject { |key, _| HookSigner::IGNORED_CONFIG_KEYS.include?(key) }
        [name, hook_config]
      end
      digest << JSON.generate([namespace, @gem_name, settings])
      specifications.each do |spec|
        digest << JSON.generate([spec.full_name, spec.require_paths,
                                 spec.runtime_dependencies.map(&:to_s).sort])
        gem_roots(spec).each_with_index do |root, index|
          digest << JSON.generate(index)
          sign_directory(digest, root)
        end
      end
      digest.hexdigest
    end

    def gem_roots(spec)
      roots = [spec.full_gem_path] + spec.full_require_paths
      roots = roots.select { |root| File.directory?(root) }.
        map { |root| File.realpath(root) }.uniq
      if roots.empty?
        raise Overcommit::Exceptions::HookLoadError,
              "Unable to find contents of gem #{spec.full_name} for approval"
      end

      roots.reject do |root|
        roots.any? { |parent| root.start_with?(parent + File::SEPARATOR) }
      end.sort
    end

    # Cover helpers, data, added/deleted files, and native extensions, rather
    # than just the selected hook file or a gem's potentially incomplete manifest.
    def sign_directory(digest, root)
      Find.find(root, ignore_error: false) do |path|
        if File.basename(path) == '.git'
          Find.prune
        elsif File.symlink?(path)
          raise Overcommit::Exceptions::HookLoadError,
                "Gem plugin approvals cannot cover symbolic links: #{path}"
        elsif File.file?(path)
          relative = path.delete_prefix(root + File::SEPARATOR)
          digest << JSON.generate([relative, Digest::SHA256.file(path).hexdigest])
        end
      end
    rescue SystemCallError => e
      raise Overcommit::Exceptions::HookLoadError,
            "Unable to read gem plugin #{@gem_name}: #{e.message}"
    end

    def signature_store
      @signature_store ||= Overcommit::Signature.new(
        "overcommit.#{@context.hook_class_name}.#{namespace}.gemsignature"
      )
    end
  end
end
