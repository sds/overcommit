require 'spec_helper'

describe Overcommit::Hook::CommitMsg::RussianNovel do
  let(:config)  { Overcommit::ConfigurationLoader.default_configuration }
  let(:context) { double('context') }
  subject { described_class.new(config, context) }

  before do
    context.stub(:commit_message_lines).and_return(commit_msg)
  end

  context 'when message contains fewer than 30 lines' do
    let(:commit_msg) { ['A single line'] * 10 }

    it { should pass }
  end

  context 'when message contains at least 30 lines' do
    let(:commit_msg) { ['A single line'] * 30 }

    it { should warn }
  end
end
