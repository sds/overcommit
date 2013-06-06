require 'spec_helper'

describe Overcommit::GitHook::TextWidth do
  context 'when subject is longer than 60 characters' do
    let(:commit_msg) { 'A' * 61 }
    it { should warn /subject/ }
  end

  context 'when subject is 60 characters or fewer' do
    let(:commit_msg) { 'A' * 60 }
    it { should pass }
  end

  context 'when a line in the message is longer than 72 characters' do
    let(:commit_msg) { <<-MSG }
      Some summary

      This line is longer than 72 characters which is clearly be seen by count.
    MSG

    it { should warn /72 char/ }
  end

  context 'when all lines in the message are fewer than 72 characters' do
    let(:commit_msg) { <<-MSG }
      Some summary

      A reasonable line.

      Another reasonable line.
    MSG

    it { should pass }
  end
end
