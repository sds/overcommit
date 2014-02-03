require 'spec_helper'

describe Overcommit::Hook::CommitMsg::HardTabs do
  let(:config)  { Overcommit::ConfigurationLoader.default_configuration }
  let(:context) { double('context') }
  let(:subject) { described_class.new(config, context) }

  before do
    subject.stub(:commit_message).and_return(commit_msg)
  end

  context 'when message contains hard tabs' do
    let(:commit_msg) { "This is a hard-tab\tcommit message" }

    it { should warn }
  end

  context 'when message does not contain hard tabs' do
    let(:commit_msg) { 'No hard tabs to be found' }

    it { should pass }
  end
end
