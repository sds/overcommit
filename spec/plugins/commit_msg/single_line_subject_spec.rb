require 'spec_helper'

describe Overcommit::GitHook::SingleLineSubject do
  context 'with a single line' do
    let(:commit_msg) { 'Initial commit' }
    it { should pass }
  end

  context 'with a newline separating subject from body' do
    let(:commit_msg) { <<-MSG }
      Initial commit

      Mostly cats so far.
    MSG

    it { should pass }
  end

  context 'with a multiline subject' do
    let(:commit_msg) { <<-MSG }
      Initial commit where I forget about commit message
      standards and decide to hard-wrap my subject.
    MSG

    it { should warn /single line/ }
  end
end
