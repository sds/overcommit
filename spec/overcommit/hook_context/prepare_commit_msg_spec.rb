require 'spec_helper'
require 'overcommit/hook_context/prepare_commit_msg'

describe Overcommit::HookContext::PrepareCommitMsg do
  let(:config) { double('config') }
  let(:args) { [commit_msg_filename, commit_msg_source] }
  let(:commit_msg_filename) { 'message-template.txt' }
  let(:commit_msg_source) { :file }
  let(:commit) { 'SHA-1 here' }
  let(:input) { double('input') }
  let(:context) { described_class.new(config, args, input) }

  describe '#commit_msg_filename' do
    subject { context.commit_msg_filename }

    it { should == commit_msg_filename }
  end

  describe '#commit_msg_source' do
    subject { context.commit_msg_source }

    it { should == commit_msg_source }
  end

  describe '#commit' do
    subject { context.commit }

    context "source isn't :commit" do
      it { should == `git rev-parse HEAD` }
    end

    context 'source is :commit' do
      let(:args) { [commit_msg_filename, :commit, commit] }

      it { should == commit }
    end
  end
end
