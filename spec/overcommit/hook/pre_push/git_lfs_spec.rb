require 'spec_helper'

describe Overcommit::Hook::PrePush::GitLfs do
  let(:config)  { Overcommit::ConfigurationLoader.default_configuration }
  let(:context) { double('context', remote_name: 'remote_name', remote_url: 'remote_url') }
  subject { described_class.new(config, context) }

  let(:result) { double('result') }

  before do
    subject.stub(:execute).and_return(result)
  end

  context 'when git-lfs is not on path' do
    before do
      result.stub(success?: false, stderr: '')
    end

    it { should warn }
  end

  context 'when git lfs hook exits successfully' do
    before do
      result.stub(success?: true, stderr: '')
    end

    it { should pass }
  end

  context 'when git lfs hook exits unsuccessfully' do
    before do
      # First for checking that git-lfs is on path, second for calling the hook itself
      result.stub(:success?).and_return(true, false)
      result.stub(:stderr).and_return('', 'error: failed to push some refs')
    end

    it { should fail_hook }
  end
end
