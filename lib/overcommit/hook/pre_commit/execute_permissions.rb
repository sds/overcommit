module Overcommit::Hook::PreCommit
  # Checks for files with execute permissions, which are usually not necessary
  # in source code files (and are typically caused by a misconfigured editor
  # assigning incorrect default permissions).
  #
  # Protip: if you have some files that you want to allow execute permissions
  # on, you can disable this hook for those files by using the `exclude` option
  # on your .overcommit.yml file. Example:
  #
  #   ExecutePermissions:
  #     enabled: true
  #     exclude:
  #       - 'path/to/my/file/that/should/have/execute/permissions.sh'
  #       - 'directory/that/should/have/execute/permissions/**/*'
  class ExecutePermissions < Base
    def run
      file_modes = {}

      # We have to look in two places to determine the execute permissions of a
      # file. The first is the Git tree for currently known file modes of all
      # files, the second is the index for any staged changes to file modes.
      # Staged changes take priority if they exist.
      #
      # This complexity is necessary because this hook can be run in the RunAll
      # context, where there may be no staged changes but we stil want to check
      # the permissions.
      extract_from_git_tree(file_modes) unless initial_commit?
      extract_from_git_index(file_modes)

      file_modes.map do |file, mode|
        next unless execute_permissions?(mode)

        Overcommit::Hook::Message.new(
          :error,
          file,
          nil,
          "File #{file} has unnecessary execute permissions",
        )
      end.compact
    end

    private

    def extract_from_git_tree(file_modes)
      result = execute(%w[git ls-tree HEAD --], args: applicable_files)
      raise 'Unable to access git tree' unless result.success?

      result.stdout.split("\n").each do |line|
        mode, _type, _hash, file = line.split(/\s+/, 4)
        file_modes[file] = mode
      end
    end

    def extract_from_git_index(file_modes)
      result = execute(%w[git diff --raw --cached --no-color --], args: applicable_files)
      raise 'Unable to access git index' unless result.success?

      result.stdout.split("\n").each do |line|
        _old_mode, new_mode, _old_hash, _new_hash, _status, file = line.split(/\s+/, 6)
        file_modes[file] = new_mode
      end
    end

    # Check if the 1st bit is toggled, indicating execute permissions.
    #
    # Git tracks only execute permissions, not individual read/write/execute
    # permissions for user, group, and other, since that concept does not exist
    # on all operating systems. If any of the user/group/other permissions
    # have the executable bit set, they all will. Thus we check the first bit.
    def execute_permissions?(mode)
      (mode.to_i(8) & 1) == 1
    end
  end
end
