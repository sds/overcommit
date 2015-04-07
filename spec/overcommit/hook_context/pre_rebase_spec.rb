require 'spec_helper'
require 'overcommit/hook_context/pre_rebase'

describe Overcommit::HookContext::PreRebase do
  let(:config) { double('config') }
  let(:args) { [upstream_branch, rebased_branch] }
  let(:upstream_branch) { 'master' }
  let(:rebased_branch) { 'topic' }
  let(:input) { double('input') }
  let(:context) { described_class.new(config, args, input) }

  describe '#upstream_branch' do
    subject { context.upstream_branch }

    it { should == upstream_branch }
  end

  describe '#rebased_branch' do
    subject { context.rebased_branch }

    it { should == rebased_branch }

    context 'when rebasing current branch' do
      let(:rebased_branch) { nil }
      let(:current_branch) { 'master' }

      around do |example|
        repo do
          `git checkout -b #{current_branch} &> /dev/null`
          example.run
        end
      end

      it { should == current_branch }
    end
  end

  describe '#fast_forward?' do
    subject { context.fast_forward? }

    context 'when upstream branch is descendent from rebased branch' do
      before do
        context.stub(:rebased_commits).and_return([])
      end

      it { should == true }
    end

    context 'when upstream branch is not descendent from rebased branch' do
      before do
        context.stub(:rebased_commits).and_return([random_hash])
      end

      it { should == false }
    end
  end

  describe '#detached_head?' do
    subject { context.detached_head? }

    context 'when rebasing a detached HEAD' do
      let(:rebased_branch) { '' }

      it { should == true }
    end

    context 'when rebasing a branch' do
      let(:rebased_branch) { 'topic' }

      it { should == false }
    end
  end

  describe '#rebased_commits' do
    subject { context.rebased_commits }

    let(:base_branch) { 'master' }
    let(:topic_branch_1) { 'topic-1' }
    let(:topic_branch_2) { 'topic-2' }

    around do |example|
      repo do
        `git checkout -b #{base_branch} &> /dev/null`
        `git commit --allow-empty -m "Initial Commit"`
        `git checkout -b #{topic_branch_1} &> /dev/null`
        `git commit --allow-empty -m "Hello World"`
        `git checkout -b #{topic_branch_2} #{base_branch} &> /dev/null`
        `git commit --allow-empty -m "Hello Again"`
        example.run
      end
    end

    context 'when upstream branch is descendent from rebased branch' do
      let(:upstream_branch) { topic_branch_1 }
      let(:rebased_branch) { base_branch }

      it { should be_empty }
    end

    context 'when upstream branch is not descendent from rebased branch' do
      let(:upstream_branch) { topic_branch_1 }
      let(:rebased_branch) { topic_branch_2 }

      it { should_not be_empty }
    end
  end
end
