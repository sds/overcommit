require 'spec_helper'

describe Overcommit::Hook::PrePush::ProtectedBranches do
  let(:config)  { Overcommit::ConfigurationLoader.default_configuration }
  let(:context) { double('context') }
  subject { described_class.new(config, context) }

  let(:protected_branch) { 'master' }
  let(:unprotected_branch) { 'other' }
  let(:pushed_ref) { double('pushed_ref') }

  before do
    subject.stub(:branches).and_return([protected_branch])
    context.stub(:pushed_refs).and_return([pushed_ref])
  end

  context 'when pushing to unprotected branch' do
    before do
      pushed_ref.stub(:remote_ref).and_return("refs/heads/#{unprotected_branch}")
    end

    context 'when ref is not deleted or force-pushed' do
      before do
        pushed_ref.stub(deleted?: false, forced?: false)
      end

      it { should pass }
    end

    context 'when ref is deleted' do
      before do
        pushed_ref.stub(deleted?: true)
      end

      it { should pass }
    end

    context 'when ref is force-pushed' do
      before do
        pushed_ref.stub(deleted?: false, forced?: true)
      end

      it { should pass }
    end
  end

  context 'when pushing to protected branch' do
    before do
      pushed_ref.stub(:remote_ref).and_return("refs/heads/#{protected_branch}")
    end

    context 'when ref is not deleted or force-pushed' do
      before do
        pushed_ref.stub(deleted?: false, forced?: false)
      end

      it { should pass }
    end

    context 'when ref is deleted' do
      before do
        pushed_ref.stub(deleted?: true)
      end

      it { should fail_hook }
    end

    context 'when ref is force-pushed' do
      before do
        pushed_ref.stub(deleted?: false, forced?: true)
      end

      it { should fail_hook }
    end
  end
end
