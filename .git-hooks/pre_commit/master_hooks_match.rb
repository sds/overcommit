# frozen_string_literal: true

require 'fileutils'

module Overcommit::Hook::PreCommit
  # Ensures all master hooks have the same content.
  #
  # This is necessary because we can't use symlinks to link all the hooks in the
  # template directory to the master `overcommit-hook` file, since symlinks are
  # not supported on Windows.
  class MasterHooksMatch < Base
    def run
      hooks_dir = File.join('template-dir', 'hooks')
      master_hook = File.join(hooks_dir, 'overcommit-hook')
      Dir.glob(File.join(hooks_dir, '*')).each do |hook_path|
        unless FileUtils.compare_file(master_hook, hook_path)
          return [
            :fail,
            "Template directory hook '#{hook_path}' does not match '#{master_hook}'!\n" \
            "Run `cp #{master_hook} #{hook_path}`"
          ]
        end
      end

      :pass
    end
  end
end
