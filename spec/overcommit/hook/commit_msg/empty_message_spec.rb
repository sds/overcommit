require 'spec_helper'

describe Overcommit::Hook::CommitMsg::EmptyMessage do
  let(:config)  { Overcommit::ConfigurationLoader.default_configuration }
  let(:context) { double('context') }
  subject { described_class.new(config, context) }

  before do
    context.stub(:empty_message?).and_return(commit_msg.strip.empty?)
  end

  context 'when commit message is empty' do
    let(:commit_msg) { '' }

    it { should fail_hook }
  end

  context 'when commit message contains only whitespace' do
    let(:commit_msg) { ' ' }

    it { should fail_hook }
  end

  context 'when commit message is not empty' do
    let(:commit_msg) { 'Some commit message' }

    it { should pass }
  end
end
