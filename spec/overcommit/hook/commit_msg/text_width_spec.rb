require 'spec_helper'

describe Overcommit::Hook::CommitMsg::TextWidth do
  let(:config)  { Overcommit::ConfigurationLoader.default_configuration }
  let(:context) { double('context') }
  subject { described_class.new(config, context) }

  before do
    context.stub(:commit_message_lines).and_return(commit_msg.lines.to_a)
    context.stub(:empty_message?).and_return(commit_msg.empty?)
  end

  context 'when commit message is empty' do
    let(:commit_msg) { '' }

    it { should pass }
  end

  context 'when subject is longer than 60 characters' do
    let(:commit_msg) { 'A' * 61 }

    it { should warn /subject/ }
  end

  context 'when subject is 60 characters or fewer' do
    let(:commit_msg) { 'A' * 60 }

    it { should pass }
  end

  context 'when the subject is 60 characters followed by a newline' do
    let(:commit_msg) { <<-MSG }
      This is 60 characters, or 61 if the newline is counted

      A reasonable line.
    MSG

    it { should pass }
  end

  context 'when a line in the message is 72 characters followed by a newline' do
    let(:commit_msg) { <<-MSG }
      Some summary

      This line has 72 characters, but with newline it has 73 characters
      That shouldn't be a problem.
    MSG

    it { should pass }
  end

  context 'when a line in the message is longer than 72 characters' do
    let(:commit_msg) { <<-MSG }
      Some summary

      This line is longer than 72 characters which is clearly be seen by count.
    MSG

    it { should warn('Line 3 of commit message has > 72 characters') }
  end

  context 'when all lines in the message are fewer than 72 characters' do
    let(:commit_msg) { <<-MSG }
      Some summary

      A reasonable line.

      Another reasonable line.
    MSG

    it { should pass }
  end

  context 'when subject and a line in the message is longer than the limits' do
    let(:commit_msg) { <<-MSG }
      A subject line that is way too long. A subject line that is way too long.

      A message line that is way too long. A message line that is way too long.
    MSG

    it { should warn /keep.*subject <= 60.*\n.*line 3.*> 72.*/im }
  end

  context 'when custom lengths are specified' do
    let(:config) do
      super().merge(Overcommit::Configuration.new(
        'CommitMsg' => {
          'TextWidth' => {
            'max_subject_width' => 70,
            'max_body_width' => 80
          }
        }
      ))
    end

    context 'when subject is longer than 70 characters' do
      let(:commit_msg) { 'A' * 71 }

      it { should warn /subject/ }
    end

    context 'when subject is 70 characters or fewer' do
      let(:commit_msg) { 'A' * 70 }

      it { should pass }
    end

    context 'when a line in the message is longer than 80 characters' do
      let(:commit_msg) { <<-MSG }
        Some summary

        This line is longer than #{'A' * 80} characters.
      MSG

      it { should warn 'Line 3 of commit message has > 80 characters' }
    end

    context 'when all lines in the message are fewer than 80 characters' do
      let(:commit_msg) { <<-MSG }
        Some summary

        A reasonable line.

        Another reasonable line.
      MSG

      it { should pass }
    end

    context 'when subject and a line in the message is longer than the limits' do
      let(:commit_msg) { <<-MSG }
        A subject line that is way too long. A subject line that is way too long.

        This line is longer than #{'A' * 80} characters.
      MSG

      it { should warn /keep.*subject <= 70.*\n.*line 3.*> 80.*/im }
    end
  end
end
