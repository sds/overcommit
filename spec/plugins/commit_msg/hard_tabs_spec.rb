require 'spec_helper'

describe Overcommit::GitHook::HardTabs do
  context 'when message contains a hard tab' do
    let(:commit_msg) { "This is a hard-tab\tcommit message" }
    it { should warn /hard tab/i }
  end

  context 'when message does not contain a hard tab' do
    let(:commit_msg) { 'This is a hard-tab-less commit message' }
    it { should pass }
  end
end
