# frozen_string_literal: true

require 'spec_helper'

describe Overcommit::Hook::PreRebase::MergedCommits do
  let(:config)  { Overcommit::ConfigurationLoader.default_configuration }
  let(:context) { double('context') }
  subject { described_class.new(config, context) }

  let(:master_branch) { 'master' }

  before do
    subject.stub(:branches) { [master_branch] }
  end

  context 'when rebasing a detached HEAD' do
    before do
      context.stub(:detached_head?) { true }
    end

    it { should pass }
  end

  context 'when there are no commits to rebase' do
    before do
      context.stub(:detached_head?) { false }
      context.stub(:rebased_commits) { [] }
    end

    it { should pass }
  end

  context 'when there are commits to rebase' do
    let(:commit_sha1) { random_hash }
    let(:rebased_branch) { 'topic' }

    before do
      context.stub(:detached_head?) { false }
      context.stub(:rebased_commits) { [commit_sha1] }
    end

    context 'when commits have not yet been merged' do
      before do
        Overcommit::GitRepo.stub(:branches_containing_commit).
          with(commit_sha1) { [rebased_branch] }
      end

      it { should pass }
    end

    context 'when commits have already been merged' do
      before do
        Overcommit::GitRepo.stub(:branches_containing_commit).
          with(commit_sha1) { [rebased_branch, master_branch] }
      end

      it { should fail_hook }

      it 'uses configured protected branches and names them in the failure' do
        settings = { 'PreRebase' => { 'MergedCommits' => { 'branches' => ['release'] } } }
        configured = config.merge(Overcommit::Configuration.new(settings))
        allow(Overcommit::GitRepo).to receive(:branches_containing_commit).
          with(commit_sha1).and_return(['release'])
        hook = described_class.new(configured, context)

        expect(hook.run).to eq([
          :fail, 'Cannot rebase commits that have already been merged into one of release'
        ])
      end
    end
  end
end
