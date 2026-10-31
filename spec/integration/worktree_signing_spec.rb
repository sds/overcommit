# frozen_string_literal: true

require 'spec_helper'
require 'yaml'

describe 'configuration file signing with multiple worktrees' do
  let(:enable_verification) { true }
  let(:verify_signatures) { true }

  let(:config) do
    {
      'verify_signatures' => verify_signatures,
      'CommitMsg' => {
        'ALL' => { 'enabled' => false },
      },
      'PreCommit' => {
        'ALL' => { 'enabled' => false },
      },
    }
  end

  let(:linked_config) { config }
  let(:sign_linked_worktree) { true }

  around do |example|
    repo do
      `git config --local extensions.worktreeConfig true` if worktree_config
      `git commit --allow-empty -m "Initial commit"`
      linked_worktree = File.join(File.dirname(Dir.pwd), 'linked-worktree')
      result = Overcommit::Utils.execute(
        %W[git worktree add -b linked-worktree #{linked_worktree}],
      )
      raise "Unable to create worktree: #{result.stderr}" unless result.success?

      echo(config.to_yaml, '.overcommit.yml')
      `overcommit --install > #{File::NULL}`
      `overcommit --sign`

      Dir.chdir(linked_worktree) do
        echo(linked_config.to_yaml, '.overcommit.yml')
        `overcommit --sign` if sign_linked_worktree
      end

      @linked_worktree = linked_worktree
      example.run
    end
  end

  def commit_in_main_worktree
    shell(%w[git commit --allow-empty -m Test])
  end

  def commit_in_linked_worktree
    Dir.chdir(@linked_worktree) { shell(%w[git commit --allow-empty -m Test]) }
  end

  context 'when the worktrees have different configurations' do
    let(:linked_config) do
      config.merge('PreCommit' => config['PreCommit'].merge('AuthorName' => { 'enabled' => true }))
    end

    context 'and extensions.worktreeConfig is not enabled' do
      let(:worktree_config) { false }

      it 'reports a signature error in the worktree signed first' do
        result = commit_in_main_worktree
        result.status.should_not == 0
        result.stderr.should include 'Signature of configuration file has changed!'
      end
    end

    context 'and extensions.worktreeConfig is enabled' do
      let(:worktree_config) { true }

      it 'does not report a signature error in either worktree' do
        commit_in_main_worktree.status.should == 0
        commit_in_linked_worktree.status.should == 0
      end
    end
  end

  context 'when verify_signatures is false and only the main worktree is signed' do
    let(:verify_signatures) { false }
    let(:sign_linked_worktree) { false }

    context 'and extensions.worktreeConfig is not enabled' do
      let(:worktree_config) { false }

      it 'shares the recorded verify_signatures setting with the linked worktree' do
        commit_in_linked_worktree.status.should == 0
      end
    end

    context 'and extensions.worktreeConfig is enabled' do
      let(:worktree_config) { true }

      it 'requires the linked worktree to record its own verify_signatures setting' do
        result = commit_in_linked_worktree
        result.status.should_not == 0
        result.stderr.should include 'No previously recorded signature for configuration file.'
      end
    end
  end
end
