module Overcommit::Hook::PreCommit
  # Runs `foodcritic` against any modified Ruby files from Chef directory structure.
  #
  # @see http://www.foodcritic.io/
  #
  # There are two "modes" you can run this hook in based on the repo:
  #
  # SINGLE COOKBOOK REPO MODE
  # -------------------------
  # The default. Use this if your repository contains just a single cookbook,
  # i.e. the top-level repo directory contains directories called `attributes`,
  # `libraries`, `recipes`, etc.
  #
  # To get this to work well, you'll want to set your Overcommit configuration
  # for this hook to something like:
  #
  # PreCommit:
  #   Foodcritic:
  #     enabled: true
  #     include:
  #       - 'attributes/**/*'
  #       - 'definitions/**/*'
  #       - 'files/**/*'
  #       - 'libraries/**/*'
  #       - 'providers/**/*'
  #       - 'recipes/**/*'
  #       - 'resources/**/*'
  #       - 'templates/**/*'
  #
  # MONOLITHIC REPO MODE
  # --------------------
  # Use this if you store multiple cookbooks, environments, and roles (or any
  # combination thereof) in a single repository.
  #
  # There are three configuration options relevant here:
  #
  #   * `cookbooks_directory`
  #     When set, hook will treat the path as a directory containing cookbooks.
  #     Each subdirectory of this directory will be treated as a separate
  #     cookbook.
  #
  #   * `environments_directory`
  #     When set, hook will treat the path as a directory containing environment
  #     files.
  #
  #   * `roles_directory`
  #     When set, hook will treat the given path as a directory containing role
  #     files.
  #
  # In order to run in monolithic repo mode, YOU MUST SET `cookbooks_directory`.
  # The other configuration options are optional, if you happen to store
  # environments/roles in another repo.
  #
  # To get this to work well, you'll want to set your Overcommit configuration
  # for this hook to something like:
  #
  # PreCommit:
  #   Foodcritic:
  #     enabled: true
  #     cookbooks_directory: 'cookbooks'
  #     environments_directory: 'environments'
  #     roles_directory: 'roles'
  #     include:
  #       - 'cookbooks/**/*'
  #       - 'environments/**/*'
  #       - 'roles/**/*'
  #
  # ADDITIONAL CONFIGURATION
  # ------------------------
  # You can disable rules using the `flags` hook option. For example:
  #
  # PreCommit:
  #   Foodcritic:
  #     enabled: true
  #     ...
  #     flags:
  #       - '--epic-fail=any'
  #       - '-t~FC011' # Missing README in markdown format
  #       - '-t~FC064' # Ensure issues_url is set in metadata
  #
  # Any other command line flag supported by the `foodcritic` executable can be
  # specified here.
  #
  # If you want the hook run to fail (and not just warn), set the `on_warn`
  # option for the hook to `fail`:
  #
  # PreCommit:
  #   Foodcritic:
  #     enabled: true
  #     on_warn: fail
  #     ...
  #
  # This will treat any warnings as failures and cause the hook to exit
  # unsuccessfully.
  class Foodcritic < Base
    def run
      args = modified_cookbooks_args + modified_environments_args + modified_roles_args
      result = execute(command, args: args)

      if result.success?
        :pass
      else
        return [:warn, result.stderr + result.stdout]
      end
    end

    private

    def directories_changed(dir_prefix)
      applicable_files.
        select    { |path| path.start_with?(dir_prefix) }.
        map       { |path| path.gsub(%r{^#{dir_prefix}/}, '') }.
        group_by  { |path| path.split('/').first }.
        keys.
        map { |path| File.join(dir_prefix, path) }
    end

    def modified_environments_args
      modified('environments').map { |env| %W[-E #{env}] }.flatten
    end

    def modified_roles_args
      modified('roles').map { |role| %W[-R #{role}] }.flatten
    end

    def modified_cookbooks_args
      # Return the repo root if repository contains a single cookbook
      if !config['cookbooks_directory'] || config['cookbooks_directory'].empty?
        ['-B', Overcommit::Utils.repo_root]
      else
        # Otherwise return all modified cookbooks in the cookbook directory
        modified('cookbooks').map { |cookbook| ['-B', cookbook] }.flatten
      end
    end

    def modified(type)
      return [] if !config["#{type}_directory"] || config["#{type}_directory"].empty?
      @modified ||= {}
      @modified[type] ||= directories_changed(full_directory_path("#{type}_directory"))
    end

    def full_directory_path(config_option)
      return config[config_option] if config[config_option].start_with?(File::SEPARATOR)
      File.absolute_path(File.join(Overcommit::Utils.repo_root, config[config_option]))
    end
  end
end
