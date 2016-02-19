require 'spec_helper'

describe Overcommit::Hook::CommitMsg::MessageFormat do
  let(:config)  { Overcommit::ConfigurationLoader.default_configuration }
  let(:context) { double('context') }
  subject { described_class.new(config, context) }

  before do
    context.stub(:commit_message_lines).and_return(commit_msg.lines.to_a)
    context.stub(:empty_message?).and_return(commit_msg.empty?)
  end

  context 'when pattern is empty' do
    let(:config) do
      super().merge(Overcommit::Configuration.new(
        'CommitMsg' => {
          'MessageFormat' => {
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

    expected_message = [
      'Commit message pattern mismatch.',
      'Expected : <Issue Id> | <Commit Message Description> | <Developer(s)>',
      'Sample : DEFECT-1234 | Refactored Onboarding flow | John Doe'
    ].join("\n")

    it { should fail_hook expected_message }
  end
end
