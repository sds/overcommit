require 'spec_helper'
require 'overcommit/hook_context/pre_push'

describe Overcommit::Hook::PrePush::ProtectedBranches do
  let(:config)  { Overcommit::ConfigurationLoader.default_configuration }
  let(:context) { double('context') }
  subject { described_class.new(config, context) }

  let(:protected_branch_patterns) { ['master', 'release/*'] }
  let(:pushed_ref) do
    instance_double(Overcommit::HookContext::PrePush::PushedRef)
  end

  before do
    subject.stub(protected_branch_patterns: protected_branch_patterns)
    pushed_ref.stub(:remote_ref).and_return("refs/heads/#{pushed_ref_name}")
    context.stub(:pushed_refs).and_return([pushed_ref])
  end

  context 'when pushing to unprotected branch' do
    let(:pushed_ref_name) { 'unprotected-branch' }

    context 'when push is not destructive' do
      before do
        pushed_ref.stub(:destructive?).and_return(false)
      end

      it { should pass }
    end

    context 'when push is destructive' do
      before do
        pushed_ref.stub(:destructive?).and_return(true)
      end

      it { should pass }
    end
  end

  shared_examples_for 'protected branch' do
    context 'when push is not destructive' do
      before do
        pushed_ref.stub(:destructive?).and_return(false)
      end

      it { should pass }
    end

    context 'when push is destructive' do
      before do
        pushed_ref.stub(:destructive?).and_return(true)
      end

      it { should fail_hook }
    end
  end

  context 'when pushing to protected branch' do
    context 'when branch name matches a protected branch exactly' do
      let(:pushed_ref_name) { 'master' }
      include_examples 'protected branch'
    end

    context 'when branch name matches a protected branch glob pattern' do
      let(:pushed_ref_name) { 'release/0.1.0' }
      include_examples 'protected branch'
    end
  end
end
