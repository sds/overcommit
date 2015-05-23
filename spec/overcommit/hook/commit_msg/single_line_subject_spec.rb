require 'spec_helper'

describe Overcommit::Hook::CommitMsg::SingleLineSubject do
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

  context 'when subject is separated from body by a blank line' do
    let(:commit_msg) { <<-MSG }
      Initial commit

      Mostly cats so far.
    MSG

    it { should pass }
  end

  context 'when subject is not kept to one line' do
    let(:commit_msg) { <<-MSG }
      Initial commit where I forget about commit message
      standards and decide to hard-wrap my subject

      Still mostly cats so far.
    MSG

    it { should warn }
  end
end
