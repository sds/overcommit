require 'spec_helper'

describe Overcommit::Hook::PrePush::GitLfs do
  let(:config)  { Overcommit::ConfigurationLoader.default_configuration }
  let(:context) {
    double('context',
           all_files: ['test/test_foo.rb'],
           remote_name: 'origin',
           remote_url: 'https://github.io/brigade/fake_repo',
           input_string: 'refs/heads/master master'
          )}
  subject { described_class.new(config, context) }

  context 'when git_lfs exits successfully' do
    let(:result) { double('result') }

    before do
      result.stub(:success?).and_return(true)
      subject.stub(:execute).and_return(result)
    end

    it { should pass }
  end

  context 'when git_lfs exits unsuccessfully' do
    let(:result) { double('result', stdout: "Failed running git-lfs", stderr: "Failed running git-lfs") }

    before do
      result.stub(:success?).and_return(false)
      subject.stub(:execute).and_return(result)
    end

    it { should fail_hook }
  end
end
