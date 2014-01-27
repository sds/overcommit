require 'spec_helper'

describe Overcommit::Hook::CommitMsg::TrailingPeriod do
  let(:config)  { Overcommit::ConfigurationLoader.default_configuration }
  let(:context) { double('context') }
  let(:subject) { described_class.new(config, context) }

  before do
    subject.stub(:commit_message).and_return(commit_msg.split("\n"))
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
