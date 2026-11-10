# frozen_string_literal: true

require 'spec_helper'
require 'yaml'

describe 'remembering previously approved configurations and hooks' do
  let(:enable_verification) { true }
  let(:plugin_path) { '.git-hooks/pre_commit/history_hook.rb' }
  let(:original_config) do
    {
      'verify_signatures' => true,
      'CommitMsg' => { 'ALL' => { 'enabled' => false } },
      'PreCommit' => {
        'ALL' => { 'enabled' => false },
        'HistoryHook' => { 'enabled' => true, 'requires_files' => false },
      },
    }
  end
  let(:original_plugin) do
    <<~RUBY_CODE
      module Overcommit::Hook::PreCommit
        class HistoryHook < Base
          def run
            :pass
          end
        end
      end
    RUBY_CODE
  end

  def run_command(*command)
    result = shell(command)
    expect(result.status).to eq(0), "#{command.inspect}: #{result.stdout}\n#{result.stderr}"
    result
  end

  def sign
    run_command('overcommit', '--sign')
    run_command('overcommit', '--sign', 'pre-commit')
  end

  def commit
    shell(%w[git commit --allow-empty -m Test])
  end

  around do |example|
    repo do
      echo(original_config.to_yaml, '.overcommit.yml')
      FileUtils.mkdir_p(File.dirname(plugin_path))
      echo(original_plugin, plugin_path)
      install_overcommit_hooks
      run_command('git', 'add', '.')
      sign
      run_command('git', 'commit', '-m', 'Original')
      @original = get_sha1('HEAD')

      changed = original_config.merge('HistoryOption' => 'changed')
      echo(changed.to_yaml, '.overcommit.yml')
      echo("#{original_plugin}\n# Changed plugin", plugin_path)
      run_command('git', 'add', '.')
      sign
      run_command('git', 'commit', '-m', 'Changed')
      @changed = get_sha1('HEAD')
      example.run
    end
  end

  it 'allows checkout between both signed configurations without signing again' do
    [@original, @changed, @original].each do |revision|
      run_command('git', 'checkout', '--detach', revision)
      commit.status.should == 0
    end
  end

  it 'rebases onto an older approved configuration and stays on the branch' do
    run_command('git', 'checkout', '-b', 'feature')
    echo('feature', 'feature.txt')
    run_command('git', 'add', 'feature.txt')
    run_command('git', 'commit', '-m', 'Feature')

    result = run_command('git', 'rebase', '--onto', @original, @changed)
    result.stderr.should_not include('Signature of configuration file has changed')
    run_command('git', 'symbolic-ref', '--short', 'HEAD').stdout.chomp.should == 'feature'
    File.read('.overcommit.yml').should == original_config.to_yaml
    File.read(plugin_path).should == original_plugin
    File.read('feature.txt').should == "feature\n"
    commit.status.should == 0
  end

  it 'still rejects a configuration that has never been signed' do
    echo(original_config.merge('HistoryOption' => 'never approved').to_yaml, '.overcommit.yml')
    result = commit
    result.status.should_not == 0
    result.stderr.should include('Signature of configuration file has changed')
  end

  it 'still rejects plugin code that has never been signed' do
    echo("#{original_plugin}\n# Never approved", plugin_path)
    run_command('git', 'add', plugin_path)
    result = commit
    result.status.should_not == 0
    result.stderr.should include('HistoryHook')
  end

  it 'requires approval for a new combination of previously signed code and configuration' do
    # The plugin configuration and its code are signed together. Approval for
    # two combinations must not allow arbitrary recombinations of their parts.
    changed = original_config
    changed['PreCommit']['HistoryHook']['new_option'] = true
    echo(changed.to_yaml, '.overcommit.yml')
    sign
    echo(original_plugin, plugin_path)
    run_command('git', 'add', '.')
    result = commit
    result.status.should_not == 0
    result.stderr.should include('HistoryHook')
  end

  it 'allows a signed old plugin with the same configuration after reverting its code' do
    echo(original_plugin, plugin_path)
    run_command('git', 'add', plugin_path)
    commit.status.should == 0
  end

  it 'migrates configuration and plugin approvals created by older releases' do
    logger = Overcommit::Logger.new(StringIO.new)
    config = Overcommit::ConfigurationLoader.new(logger, verify: false).load_repo_config
    # These are the pre-history signature formats, independent of the new store.
    config_signature = Digest::SHA256.hexdigest(config.instance_variable_get(:@hash).to_json)
    hook_config = config.for_hook('HistoryHook', 'PreCommit').dup
    hook_config.delete('skip')
    hook_signature = Digest::SHA256.hexdigest(File.read(plugin_path) + hook_config.to_s)
    FileUtils.rm_rf(File.join(Overcommit::Utils.git_dir, 'overcommit-signatures'))
    run_command('git', 'config', '--local', 'overcommit.configuration.signature', config_signature)
    run_command('git', 'config', '--local',
                'overcommit.PreCommit.HistoryHook.signature', hook_signature)

    commit.status.should == 0
    %w[overcommit.configuration.signature overcommit.PreCommit.HistoryHook.signature].each do |key|
      shell(%W[git config --local --get #{key}]).status.should == 1
    end
    FileUtils.rm_rf(File.join(Overcommit::Utils.git_dir, 'overcommit-signatures'))
    commit.status.should_not == 0
  end

  it 'requires signing again after all local history is deleted' do
    FileUtils.rm_rf(File.join(Overcommit::Utils.git_dir, 'overcommit-signatures'))
    result = commit
    result.status.should_not == 0
    result.stderr.should include('No previously recorded signature')
    sign
    commit.status.should == 0
  end
end
