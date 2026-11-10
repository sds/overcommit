# frozen_string_literal: true

require 'digest'
require 'fileutils'

module Overcommit
  # Repository-local approvals, indexed by hook identity and SHA256 signature.
  # These files are outside Git's object database so fetching cannot add trust.
  class Signature
    def initialize(config_key)
      @config_key = config_key
      scope = Overcommit::GitConfig.signature_scope
      root = if scope == '--worktree'
               Overcommit::Utils.git_path('overcommit-signatures')
             else
               File.join(Overcommit::Utils.git_dir, 'overcommit-signatures')
             end
      @directory = File.join(root, Digest::SHA256.hexdigest(config_key))
      migrate_legacy_signature(scope)
    end

    def include?(signature)
      File.read(path(signature)) == contents(signature)
    rescue Errno::ENOENT
      false
    rescue SystemCallError => e
      raise Overcommit::Exceptions::SignatureError, "Unable to read signature history: #{e}"
    end

    def recorded?
      File.directory?(@directory)
    end

    def add(signature)
      FileUtils.mkdir_p(@directory)
      File.write(path(signature), contents(signature), mode: 'w', perm: 0o600)
    rescue SystemCallError => e
      raise Overcommit::Exceptions::SignatureError, "Unable to write signature history: #{e}"
    end

    private

    def path(signature)
      File.join(@directory, signature)
    end

    def contents(signature)
      "#{@config_key}\n#{signature}\n"
    end

    # Preserve an existing approval before removing its legacy Git config key.
    # Removing the key means deleting history files actually revokes trust.
    def migrate_legacy_signature(scope)
      result = Overcommit::Utils.execute(%W[git config #{scope} --get] + [@config_key])
      return if result.status == 1

      check_config_result(result)
      signature = result.stdout.chomp
      add(signature) if signature.match?(/\A[0-9a-f]{64}\z/)
      result = Overcommit::Utils.execute(%W[git config #{scope} --unset-all] + [@config_key])
      check_config_result(result) unless result.status == 5 # Already removed by another process.
    end

    def check_config_result(result)
      return if result.success?

      raise Overcommit::Exceptions::GitConfigError,
            "Unable to migrate local repo git config signature: #{result.stderr}"
    end
  end
end
