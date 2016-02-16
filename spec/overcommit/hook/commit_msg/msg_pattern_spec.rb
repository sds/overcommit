require 'spec_helper'

describe Overcommit::Hook::CommitMsg::MsgPattern do
  let(:config)  { Overcommit::ConfigurationLoader.default_configuration }
  let(:context) { double('context') }
  subject { described_class.new(config, context) }

  before do
    context.stub(:commit_message_lines).and_return(commit_msg.lines.to_a)
    context.stub(:empty_message?).and_return(commit_msg.empty?)
  end

  context 'when commit message is empty' do
    let(:commit_msg) { '' }

    it { should fail_hook }
  end

  context 'when pattern is empty' do
    let(:config) do
      super().merge(Overcommit::Configuration.new(
        'CommitMsg' => {
          'MsgPattern' => {
            'pattern' => nil
          }
        }
      ))
    end
    let(:commit_msg) { 'Some Message' }
    it { should pass }
  end

  context 'when message does not match the pattern' do
    let(:commit_msg) { 'Some Message' }

    it { should fail_hook "Commit message pattern mismatch.\nExpected : <Issue Id> | <Commit Message Description> | <Developer(s)>\nSample : DEFECT-1234 | Refactored Onboarding flow | John Doe" }
  end

end
