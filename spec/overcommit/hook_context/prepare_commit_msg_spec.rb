require 'spec_helper'
require 'overcommit/hook_context/prepare_commit_msg'

describe Overcommit::HookContext::PrepareCommitMsg do
  let(:config) { double('config') }
  let(:args) { [commit_message_filename, commit_message_source] }
  let(:commit_message_filename) { 'message-template.txt' }
  let(:commit_message_source) { :file }
  let(:commit) { 'SHA-1 here' }
  let(:input) { double('input') }
  let(:context) { described_class.new(config, args, input) }

  describe '#commit_message_filename' do
    subject { context.commit_message_filename }

    it { should == commit_message_filename }
  end

  describe '#commit_message_source' do
    subject { context.commit_message_source }

    it { should == commit_message_source }
  end
end
