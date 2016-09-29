module Overcommit::Hook::PreCommit
  # Runs `foodcritic` against any modified Ruby files from chef directory structure.
  #
  # @see http://www.foodcritic.io/
  #
  # Provides three configuration options:
  #
  # * `cookbooks_directory`
  #   If not set, or set to false, the current directory will be treated as a cookbook directory
  #   (the one containing recipes, libraries, etc.)
  #   If set to path (absolute or relative), hook will interpret it as a cookbooks directory
  #   (so all each subdirectory will be treated as separate cookbook)
  # * `environments_directory`
  #   If provided, the given path will be treated as environments directory
  # * `roles_directory`
  #   If provided, the given path will be treated as roles directory
  #
  # By default, none of those options is set, which means, the repo directory will be treaded
  # as a cookbook directory (with recipes, libraries etc.)
  #
  # Example:
  #
  # Foodcritic:
  #   enabled: true
  #   cookbooks_directory: './cookbooks'
  #   environments_directory: './environments'
  #   roles_directory: './roles'
  class Foodcritic < Base
    def run
      args = modified_environments_args + modified_roles_args + modified_cookbooks_args

      args += applicable_files.reject do |file|
        %w[spec test].any? { |dir| file.include?("#{File::SEPARATOR}#{dir}#{File::SEPARATOR}") }
      end - modified_environments - modified_roles if modified_cookbooks.empty?

      result = execute(command, args: args)

      if result.success?
        :pass
      else
        return [:warn, result.stdout]
      end
    end

    private

    def directories_changed(dir_prefix)
      applicable_files.
        select    { |path| path.start_with?(dir_prefix) }.
        map       { |path| path.gsub(%r{^#{dir_prefix}/}, '') }.
        group_by  { |path| path.split('/').first }.
        keys.
        map { |cookbook| File.join(dir_prefix, cookbook) }
    end

    def modified_environments_args
      modified_environments.map { |env| %W[-E #{env}] }.flatten
    end

    def modified_roles_args
      modified_roles.map { |role| %W[-R #{role}] }.flatten
    end

    def modified_cookbooks_args
      modified_cookbooks.map { |cookbook| %W[-B #{cookbook}] }.flatten
    end

    def modified_environments
      modified 'environments'
    end

    def modified_roles
      modified 'roles'
    end

    def modified_cookbooks
      modified 'cookbooks'
    end

    def modified(type)
      return [] if !config["#{type}_directory"] || config["#{type}_directory"].empty?
      @modified ||= {}
      @modified[type] ||= directories_changed(full_directory_path("#{type}_directory"))
    end

    def full_directory_path(config_option)
      return config[config_option] if config[config_option].start_with?(File::SEPARATOR)
      File.absolute_path(File.join(repo_root, config[config_option]))
    end

    def repo_root
      Overcommit::Utils.repo_root
    end
  end
end
