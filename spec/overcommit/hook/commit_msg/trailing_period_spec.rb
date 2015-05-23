require 'spec_helper'

describe Overcommit::Hook::CommitMsg::TrailingPeriod do
  let(:config)  { Overcommit::ConfigurationLoader.default_configuration }
  let(:context) { double('context') }
  subject { described_class.new(config, context) }

  before do
    context.stub(:commit_message_lines).and_return(commit_msg.split("\n"))
    context.stub(:empty_message?).and_return(commit_msg.empty?)
  end

  context 'when commit message is empty' do
    let(:commit_msg) { '' }

    it { should pass }
  end

  context 'when subject contains a trailing period' do
    let(:commit_msg) { 'This subject has a period.' }

    it { should warn }
  end

  context 'when subject does not contain a trailing period' do
    let(:commit_msg) { 'This subject has no period' }

    it { should pass }
  end
end
